#!/usr/bin/env bash
set -euo pipefail

# mirror-commit-message.sh
# Type: executable
# Build a mirror commit message from backbone-core HEAD:
#   - insert [sync] after type(scope): on the subject line
#   - keep the remaining body (release commits put the CHANGELOG URL there)
#   - drop Signed-off-by (mirror commit is re-signed)
# Usage: .github/scripts/mirror-commit-message.sh [core-repo-dir] [commit]
# Prints the message on stdout (suitable for git commit -m).

# ---- Functions --------------------------------------------------------------

usage() {
    cat << EOF
Usage:
    $(basename "$0") [core-repo-dir] [commit]

Examples:
    $(basename "$0")
    $(basename "$0") "\${GITHUB_WORKSPACE}" HEAD
    $(basename "$0") . abcdef1
EOF
}

strip_signed_off_by() {
    local message="$1"
    printf '%s\n' "${message}" | sed '/^Signed-off-by:/d'
}

insert_sync_marker() {
    local subject="$1"
    if [[ "${subject}" == *": "* ]]; then
        printf '%s\n' "${subject%%: *}: [sync] ${subject#*: }"
    else
        printf '%s\n' "[sync] ${subject}"
    fi
}

print_commit_message() {
    local subject="$1"
    local body="$2"

    printf '%s\n' "${subject}"
    if [[ -n "${body}" ]]; then
        printf '%s' "${body}"
        [[ "${body}" == *$'\n' ]] || printf '\n'
    fi
}

# ---- Main -------------------------------------------------------------------

main() {
    local core_repo="${1:-${GITHUB_WORKSPACE:-.}}"
    local core_commit="${2:-HEAD}"
    local message subject body

    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    message="$(strip_signed_off_by "$(git -C "${core_repo}" log -1 --format=%B "${core_commit}")")"
    subject="$(printf '%s\n' "${message}" | head -n 1)"
    body="$(printf '%s\n' "${message}" | tail -n +2)"
    subject="$(insert_sync_marker "${subject}")"
    print_commit_message "${subject}" "${body}"
}

main "$@"
