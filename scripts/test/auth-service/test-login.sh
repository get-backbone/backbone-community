#!/usr/bin/env bash
set -euo pipefail

# test-login.sh
# Type: executable
# Test login endpoint for auth service.

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
    validate_dependencies
    export AWS_PAGER=""

    curl -s -X POST http://localhost:8100/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username": "bob@example.com", "password": "Rogue_One1"}' | jq
}

main "$@"
