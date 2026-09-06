#!/usr/bin/env bash
set -euo pipefail

# perf-seed-cognito.sh
# Type: executable
# Seed perf load-test users into the Cognito actor pool (Floci or real AWS).
# Usage: ./perf-seed-cognito.sh --target local|aws

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SEED_ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=scripts/lib/common.sh
source "${SEED_ROOT_DIR}/../../lib/common.sh"
# shellcheck source=scripts/test/seed/test-users-lib.sh
source "${SEED_ROOT_DIR}/test-users-lib.sh"

# ---- Functions --------------------------------------------------------------

usage() {
    echo "Usage: $(basename "$0") --target local|aws" >&2
}

validate_dependencies() {
    local target="${1:-}"

    require_cli gum

    if [[ "$target" == "local" ]]; then
        require_cli awslocal
    elif [[ "$target" == "aws" ]]; then
        require_cli aws
    fi
}

load_actor_pool_id_floci() {
    awslocal ssm get-parameter \
        --name COGNITO_ACTOR_POOL_ID \
        --query Parameter.Value \
        --output text
}

# ---- Main -------------------------------------------------------------------

main() {
    local target=""
    local cognito_cli actor_pool_id

    while [[ $# -gt 0 ]]; do
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

    if [[ "$target" != "local" && "$target" != "aws" ]]; then
        usage
        exit 1
    fi

    validate_dependencies "$target"

    if [[ "$target" == "local" ]]; then
        cognito_cli=awslocal
        actor_pool_id="$(load_actor_pool_id_floci)"
        echo "🌱 Seeding perf Cognito users on Floci."
    else
        # shellcheck source=scripts/aws/cognito/config.sh
        source "${SEED_ROOT_DIR}/../../aws/cognito/config.sh"
        cognito_cli=aws
        actor_pool_id="$COGNITO_ACTOR_POOL_ID"
        echo "🌱 Seeding perf Cognito users on AWS..."
    fi

    seed_cognito_users_from_tsv "$cognito_cli" "$actor_pool_id" "$(perf_load_users_tsv_path)"
}

main "$@"
