#!/usr/bin/env bash
# test-users-lib.sh
# Type: module (source only — do not execute directly)
# Shared Cognito user seeding helpers for scripts/test/seed.
# Callers pass the CLI explicitly: awslocal (Floci IT) or aws (perf / real AWS).

# ---- Constants --------------------------------------------------------------

readonly TEST_USERS_SEED_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Functions --------------------------------------------------------------

it_fixture_users_tsv_path() {
    echo "${TEST_USERS_SEED_DIR}/it/it-fixture-users.tsv"
}

perf_load_users_tsv_path() {
    echo "${TEST_USERS_SEED_DIR}/perf/perf-load-users.tsv"
}

actor_pool_user_sub() {
    local cognito_cli=$1
    local pool_id=$2
    local username=$3

    "${cognito_cli}" cognito-idp admin-get-user \
        --user-pool-id "$pool_id" \
        --username "$username" \
        --query 'UserAttributes[?Name==`sub`].Value' \
        --output text
}

seed_cognito_users_from_tsv() {
    local cognito_cli=$1
    local pool_id=$2
    local tsv_path=$3

    log_info "👥 Creating test users for user pool $pool_id..."

    while IFS=$'\t' read -r email _display_name password || [ -n "${email:-}" ]; do
        [[ "$email" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${email// /}" ]] && continue

        if ! "${cognito_cli}" cognito-idp admin-get-user --user-pool-id "$pool_id" --username "$email" > /dev/null 2>&1; then
            "${cognito_cli}" cognito-idp admin-create-user \
                --user-pool-id "$pool_id" \
                --username "$email" \
                --user-attributes Name=email,Value="$email" Name=email_verified,Value=true \
                --temporary-password "$password" \
                --message-action SUPPRESS > /dev/null
        fi

        "${cognito_cli}" cognito-idp admin-set-user-password \
            --user-pool-id "$pool_id" \
            --username "$email" \
            --password "$password" \
            --permanent > /dev/null

        log_info "✅ Test user created/updated: $email"
    done < "$tsv_path"
    echo
}
