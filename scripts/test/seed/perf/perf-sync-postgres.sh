#!/usr/bin/env bash
set -euo pipefail

# perf-sync-postgres.sh
# Type: executable
# Sync perf load-test Cognito users into Postgres (local Docker or AWS RDS).
# Cognito reads match --target: awslocal/Floci or real AWS.
# Usage: ./perf-sync-postgres.sh --target local|aws

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SEED_ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=scripts/lib/common.sh
source "${SEED_ROOT_DIR}/../../lib/common.sh"
# shellcheck source=scripts/test/seed/test-users-lib.sh
source "${SEED_ROOT_DIR}/test-users-lib.sh"

# ---- Constants --------------------------------------------------------------

readonly POSTGRES_CONTAINER="postgres"
readonly POSTGRES_DB="backbone"
readonly POSTGRES_USER="postgres"
readonly BACKBONE_RDS_USER_NAME="backbone"
readonly BACKBONE_RDS_DATABASE_NAME="backbone"
readonly BACKBONE_RDS_PORT="5432"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    local target="${1:-}"

    require_cli gum

    if [[ "$target" == "local" ]]; then
        require_cli awslocal
        require_cli docker
    elif [[ "$target" == "aws" ]]; then
        require_cli aws
        require_cli psql
    fi
}

usage() {
    echo "Usage: $(basename "$0") --target local|aws" >&2
}

load_actor_pool_id_floci() {
    awslocal ssm get-parameter \
        --name COGNITO_ACTOR_POOL_ID \
        --query Parameter.Value \
        --output text
}

run_psql_local() {
    docker exec "$POSTGRES_CONTAINER" psql -q -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 "$@"
}

run_psql_aws() {
    PGPASSWORD="$PGPASSWORD" psql -q "host=$PGHOST port=$BACKBONE_RDS_PORT dbname=$BACKBONE_RDS_DATABASE_NAME user=$BACKBONE_RDS_USER_NAME sslmode=require" -v ON_ERROR_STOP=1 "$@"
}

# ---- Main -------------------------------------------------------------------

main() {
    local target=""
    local cognito_cli actor_pool_id sql_runner
    local email display_name sub email_sql display_name_sql

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target)
                target="${2:-}"
                shift 2
                ;;
            *)
                usage
                exit 1
                ;;
        esac
    done

    if [ "$target" != "local" ] && [ "$target" != "aws" ]; then
        usage
        exit 1
    fi

    validate_dependencies "$target"

    if [ "$target" = "local" ]; then
        cognito_cli=awslocal
        actor_pool_id="$(load_actor_pool_id_floci)"
        sql_runner="run_psql_local"
    else
        # shellcheck source=scripts/aws/cognito/config.sh
        source "${SEED_ROOT_DIR}/../../aws/cognito/config.sh"
        # shellcheck source=scripts/aws/rds-cdk-exports.sh
        source "${SEED_ROOT_DIR}/../../aws/rds-cdk-exports.sh"
        backbone_load_rds_env_from_cdk
        cognito_cli=aws
        actor_pool_id="$COGNITO_ACTOR_POOL_ID"
        sql_runner="run_psql_aws"
    fi

    log_info "👥 Syncing perf users to Postgres (target=$target)..."

    while IFS=$'\t' read -r email display_name _password || [ -n "${email:-}" ]; do
        [[ "$email" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${email// /}" ]] && continue

        sub="$(actor_pool_user_sub "$cognito_cli" "$actor_pool_id" "$email")"
        email_sql="${email//\'/\'\'}"
        display_name_sql="${display_name//\'/\'\'}"

        "$sql_runner" -c "INSERT INTO actor.actors (actor_id, email_address, username, timestamp) VALUES ('$sub', '$email_sql', '$display_name_sql', NOW()) ON CONFLICT (email_address) DO UPDATE SET actor_id = EXCLUDED.actor_id, username = EXCLUDED.username, timestamp = EXCLUDED.timestamp;"
        log_info "Synced perf user to Postgres $email"
    done < "$(perf_load_users_tsv_path)"
}

main "$@"
