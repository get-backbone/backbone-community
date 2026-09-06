#!/usr/bin/env bash
set -euo pipefail

# dummy-resume-post.sh
# Type: executable
# Test resume upload and retrieval.

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
    validate_dependencies
    export AWS_PAGER=""

    echo '➡️ parsing and storing resume...'
    curl -s -X POST http://localhost:8101/resumes \
        -H "Content-Type: multipart/form-data" \
        -F "resume=@test/document-service/form-dummy-resume.pdf" \
        -F "actorId=12345678" |
        jq

    echo '⬅️ retrieving resume: '
    awslocal dynamodb query \
        --table-name RESUMES \
        --index-name ActorIndex \
        --key-condition-expression "emailAddress = :email" \
        --expression-attribute-values '{":email":{"S":"slips11@gmail.com"}}' \
        --projection-expression "emailAddress, parseTimestamp"
}

main "$@"
