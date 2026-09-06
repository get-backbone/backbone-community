#!/usr/bin/env bash
set -euo pipefail

# it-sync-postgres.sh
# Type: executable
# Sync Floci IT Cognito fixture users into local Docker Postgres.
# Usage: ./it-sync-postgres.sh
# Prerequisite: task seed:it cognito seed + actor-service Flyway (actor.actors).

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

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli awslocal
    require_cli gum
    require_cli docker
}

load_floci_actor_pool_id() {
    COGNITO_ACTOR_POOL_ID="$(awslocal ssm get-parameter \
        --name COGNITO_ACTOR_POOL_ID \
        --query Parameter.Value \
        --output text)"
}

run_psql_local() {
    docker exec "$POSTGRES_CONTAINER" psql -q -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 "$@"
}

# ---- Main -------------------------------------------------------------------

main() {
    local email display_name sub email_sql display_name_sql

    validate_dependencies
    load_floci_actor_pool_id

    log_info "👥 Syncing Floci IT users to local Postgres actors table..."

    while IFS=$'\t' read -r email display_name _password || [ -n "${email:-}" ]; do
        [[ "$email" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${email// /}" ]] && continue

        sub="$(actor_pool_user_sub awslocal "$COGNITO_ACTOR_POOL_ID" "$email")"
        email_sql="${email//\'/\'\'}"
        display_name_sql="${display_name//\'/\'\'}"

        run_psql_local -c "INSERT INTO actor.actors (actor_id, email_address, username, timestamp) VALUES ('$sub', '$email_sql', '$display_name_sql', NOW()) ON CONFLICT (email_address) DO UPDATE SET actor_id = EXCLUDED.actor_id, username = EXCLUDED.username, timestamp = EXCLUDED.timestamp;"
        log_info "✅ Test user synced: $email"
    done < "$(it_fixture_users_tsv_path)"
}

main "$@"
