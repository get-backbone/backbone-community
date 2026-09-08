#!/usr/bin/env bash
set -euo pipefail

# mirror-commit-message.sh
# Type: executable
# Build a mirror commit message from backbone-core HEAD:
#   - insert [sync] after type(scope): on the subject line
#   - rewrite "See CHANGELOG.md" to this mirror's blob URL (GitHub does not link bare paths)
#   - keep the remaining body
#   - drop Signed-off-by (mirror commit is re-signed)
# Usage: .github/scripts/mirror-commit-message.sh [core-repo-dir] [commit]
# Env:
#   MIRROR_REPO  owner/name of the mirror (e.g. get-backbone/backbone-developer)
#   VERSION      release version without v-prefix (e.g. 2.0.3)
# Prints the message on stdout (suitable for git commit -m).

# ---- Functions --------------------------------------------------------------

usage() {
    cat << EOF
Usage:
    $(basename "$0") [core-repo-dir] [commit]

Env:
    MIRROR_REPO  required for CHANGELOG link rewrite (owner/name)
    VERSION      required for CHANGELOG link rewrite (no v-prefix)

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

# Core keeps a portable "See CHANGELOG.md"; mirrors need a full URL so GitHub makes it clickable
# and each mirror points at its own tree (not a private sibling repo).
link_changelog_reference() {
    local text="$1"
    local repo="${MIRROR_REPO:-}"
    local version="${VERSION:-}"
    local changelog_url

    if [[ -z "${repo}" || -z "${version}" ]]; then
        printf '%s\n' "${text}"
        return 0
    fi

    changelog_url="https://github.com/${repo}/blob/v${version}/CHANGELOG.md"
    printf '%s\n' "${text//See CHANGELOG.md/See ${changelog_url}}"
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
    subject="$(link_changelog_reference "${subject}")"
    body="$(link_changelog_reference "${body}")"
    print_commit_message "${subject}" "${body}"
}

main "$@"
