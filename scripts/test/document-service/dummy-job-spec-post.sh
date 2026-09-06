#!/usr/bin/env bash
set -euo pipefail

# dummy-job-spec-post.sh
# Type: executable
# Test job spec upload and retrieval.

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli curl
    require_cli jq
    require_cli awslocal
}

# ---- Main -------------------------------------------------------------------

main() {
    local access_token

    validate_dependencies
    export AWS_PAGER=""

    echo '➡️ parsing and storing job spec...'
    access_token=$(curl -s -X POST http://localhost:8100/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username": "bob@example.com", "password": "Rogue_One1"}' | jq -r '.accessToken')

    curl -s -X POST http://localhost:8102/job-specs \
        -H "Content-Type: multipart/form-data" \
        -H "Authorization: Bearer $access_token" \
        -F "jobSpec=@test/document-service/form-dummy-job-spec.pdf" \
        -F "clientId=12345678" |
        jq

    echo
    echo '⬅️ retrieving resume: '
    awslocal dynamodb query \
        --table-name JOBS \
        --index-name ClientNameIndex \
        --key-condition-expression "mainEmployerName = :employer" \
        --expression-attribute-values '{":employer":{"S":"Northern Ireland Assembly"}}' \
        --projection-expression "mainEmployerName, uploadTimestamp"
}

main "$@"
