#!/usr/bin/env bash
set -euo pipefail

# it-seed-cognito.sh
# Type: executable
# Seed IT Cognito fixtures into Floci (actor-pool users + service-pool test account).
# Usage: ./it-seed-cognito.sh
# Prerequisite: task dev:floci (pools + SSM parameters on :4566).

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SEED_ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=scripts/lib/common.sh
source "${SEED_ROOT_DIR}/../../lib/common.sh"
# shellcheck source=scripts/test/seed/test-users-lib.sh
source "${SEED_ROOT_DIR}/test-users-lib.sh"
# shellcheck source=scripts/test/seed/it/it-test-accounts.sh
source "${SCRIPT_DIR}/it-test-accounts.sh"

# Pin AWS_REGION so awslocal matches Quarkus (SDK region chain; defaults to us-east-1 without ~/.aws).
export AWS_REGION="${AWS_REGION:-us-west-2}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-${AWS_REGION}}"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli awslocal
    require_cli gum
}

load_floci_pool_ids() {
    COGNITO_ACTOR_POOL_ID="$(awslocal ssm get-parameter \
        --name COGNITO_ACTOR_POOL_ID \
        --query Parameter.Value \
        --output text)"
    COGNITO_SERVICE_POOL_ID="$(awslocal ssm get-parameter \
        --name COGNITO_SERVICE_POOL_ID \
        --query Parameter.Value \
        --output text)"
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_dependencies

    echo "🌱 Seeding IT Cognito fixtures on Floci."
    load_floci_pool_ids
    seed_cognito_users_from_tsv awslocal "$COGNITO_ACTOR_POOL_ID" "$(it_fixture_users_tsv_path)"
    create_test_service_account "$COGNITO_SERVICE_POOL_ID"
}

main "$@"
