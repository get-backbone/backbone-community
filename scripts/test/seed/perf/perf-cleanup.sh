#!/usr/bin/env bash
set -euo pipefail

# perf-cleanup.sh
# Type: executable
# Cleanup perf test data in Cognito, Postgres, and S3 (Floci local or real AWS).
# Usage: ./perf-cleanup.sh --target local|aws [--preserve-load]

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SEED_ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=scripts/lib/common.sh
source "${SEED_ROOT_DIR}/../../lib/common.sh"
# shellcheck source=scripts/aws/s3-datastore-exports.sh
source "${SEED_ROOT_DIR}/../../aws/s3-datastore-exports.sh"

# ---- Constants --------------------------------------------------------------

readonly POSTGRES_CONTAINER="postgres"
readonly POSTGRES_DB="backbone"
readonly POSTGRES_USER="postgres"
readonly BACKBONE_RDS_DATABASE_NAME="backbone"
readonly BACKBONE_RDS_PORT="5432"
readonly BACKBONE_RDS_USER_NAME="backbone"

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
    echo "Usage: $(basename "$0") --target local|aws [--preserve-load]" >&2
}

load_actor_pool_id_floci() {
    awslocal ssm get-parameter \
        --name COGNITO_ACTOR_POOL_ID \
        --query Parameter.Value \
        --output text
}

delete_cognito_users_by_prefix() {
    local cognito_cli=$1
    local pool_id=$2
    local prefix=$3
    local users deleted=0

    log_info "Cognito: deleting users with email prefix \"$prefix\"..."
    users=$("${cognito_cli}" cognito-idp list-users \
        --user-pool-id "$pool_id" \
        --filter "email ^= \"$prefix\"" \
        --query "Users[].Username" \
        --output text)

    if [ -z "${users:-}" ] || [ "$users" = "None" ]; then
        log_info "Cognito: no users matched prefix \"$prefix\"."
        return
    fi

    for username in $users; do
        "${cognito_cli}" cognito-idp admin-delete-user \
            --user-pool-id "$pool_id" \
            --username "$username" > /dev/null
        deleted=$((deleted + 1))
    done

    if [ "$deleted" -gt 0 ]; then
        log_info "Cognito: removed $deleted user(s) with prefix \"$prefix\"."
    else
        log_info "Cognito: no users matched prefix \"$prefix\"."
    fi
}

cleanup_local_postgres() {
    log_info "Postgres: truncating audit.audit_events..."
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -c "TRUNCATE TABLE audit.audit_events;"
    log_info "Truncated audit.audit_events"

    log_info "Postgres: deleting actor rows matching testuser|loaduser..."
    docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -c "DELETE FROM actor.actors WHERE email_address LIKE 'testuser%@example.com' OR email_address LIKE 'loaduser%@example.com';"
    log_info "Deleted testuser|loaduser from actor.actors"
}

cleanup_aws_postgres_audit() {
    log_info "Postgres: truncating audit.audit_events..."
    PGPASSWORD="$PGPASSWORD" psql "host=$PGHOST port=$BACKBONE_RDS_PORT dbname=$BACKBONE_RDS_DATABASE_NAME user=$BACKBONE_RDS_USER_NAME sslmode=require" -v ON_ERROR_STOP=1 -c "TRUNCATE TABLE audit.audit_events;"
    log_info "Truncated audit.audit_events"
}

cleanup_aws_postgres_testuser() {
    log_info "Postgres: deleting actor rows matching testuser..."
    PGPASSWORD="$PGPASSWORD" psql "host=$PGHOST port=$BACKBONE_RDS_PORT dbname=$BACKBONE_RDS_DATABASE_NAME user=$BACKBONE_RDS_USER_NAME sslmode=require" -v ON_ERROR_STOP=1 -c "DELETE FROM actor.actors WHERE email_address LIKE 'testuser%@example.com';"
    log_info "Deleted testusers from actor.actors"
}

cleanup_aws_postgres_loaduser() {
    log_info "Postgres: deleting actor rows matching loaduser..."
    PGPASSWORD="$PGPASSWORD" psql "host=$PGHOST port=$BACKBONE_RDS_PORT dbname=$BACKBONE_RDS_DATABASE_NAME user=$BACKBONE_RDS_USER_NAME sslmode=require" -v ON_ERROR_STOP=1 -c "DELETE FROM actor.actors WHERE email_address LIKE 'loaduser%@example.com';"
    log_info "Deleted loadusers from actor.actors"
}

cleanup_local_s3() {
    local documents_bucket_name="backbone-documents"
    awslocal s3 rm "s3://${documents_bucket_name}" --recursive > /dev/null || true
}

cleanup_aws_s3() {
    local documents_bucket_name access_logs_bucket_name
    documents_bucket_name="$(backbone_documents_bucket_name_from_cdk_export)"
    aws s3 rm "s3://${documents_bucket_name}" --recursive > /dev/null
    log_info "Emptied documents bucket s3://$documents_bucket_name"

    access_logs_bucket_name="$(backbone_documents_access_logs_bucket_name "$documents_bucket_name" || true)"
    if [ -n "${access_logs_bucket_name:-}" ] && [ "$access_logs_bucket_name" != "None" ]; then
        aws s3 rm "s3://${access_logs_bucket_name}" --recursive > /dev/null
        log_info "Emptied access logs bucket s3://$access_logs_bucket_name"
    fi
}

# ---- Main -------------------------------------------------------------------

main() {
    local target=""
    local preserve_load="false"
    local cognito_cli actor_pool_id

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target)
                target="${2:-}"
                shift 2
                ;;
            --preserve-load)
                preserve_load="true"
                shift 1
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
    else
        # shellcheck source=scripts/aws/cognito/config.sh
        source "${SEED_ROOT_DIR}/../../aws/cognito/config.sh"
        cognito_cli=aws
        actor_pool_id="$COGNITO_ACTOR_POOL_ID"
    fi

    delete_cognito_users_by_prefix "$cognito_cli" "$actor_pool_id" "testuser"

    if [ "$preserve_load" != "true" ] || [ "$target" != "aws" ]; then
        delete_cognito_users_by_prefix "$cognito_cli" "$actor_pool_id" "loaduser"
    fi

    if [ "$target" = "local" ]; then
        cleanup_local_postgres
        cleanup_local_s3
    else
        # shellcheck source=scripts/aws/rds-cdk-exports.sh
        source "${SEED_ROOT_DIR}/../../aws/rds-cdk-exports.sh"
        backbone_load_rds_env_from_cdk

        cleanup_aws_postgres_audit
        cleanup_aws_postgres_testuser
        if [ "$preserve_load" != "true" ]; then
            cleanup_aws_postgres_loaduser
        fi
        cleanup_aws_s3
    fi
}

main "$@"
