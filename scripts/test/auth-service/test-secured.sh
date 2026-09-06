#!/usr/bin/env bash
set -euo pipefail

# test-secured.sh
# Type: executable
# Test secured endpoint for auth service.

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli curl
    require_cli jq
}

# ---- Main -------------------------------------------------------------------

main() {
    local access_token

    validate_dependencies
    export AWS_PAGER=""

    access_token=$(curl -s -X POST http://localhost:8100/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username": "bob@example.com", "password": "Rogue_One1"}' | jq -r '.accessToken')

    curl -i -X POST http://localhost:8100/test/secured \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $access_token"
}

main "$@"
