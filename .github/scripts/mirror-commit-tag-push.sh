#!/usr/bin/env bash
set -euo pipefail

# mirror-commit-tag-push.sh
# Type: executable
# Commit staged mirror tree changes, fast-forward push, and create an immutable version tag.
# Must run with cwd = mirror working tree (workflow working-directory).
# Usage: .github/scripts/mirror-commit-tag-push.sh
# Env:
#   GITHUB_WORKSPACE  core checkout (message source + scripts)
#   MIRROR_BRANCH     branch to push (e.g. main)
#   VERSION           release version for tag v${VERSION}

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Functions --------------------------------------------------------------

validate_env() {
    if [[ -z "${GITHUB_WORKSPACE:-}" ]]; then
        echo "GITHUB_WORKSPACE must be set to the backbone-core checkout." >&2
        exit 1
    fi
    if [[ -z "${MIRROR_BRANCH:-}" ]]; then
        echo "MIRROR_BRANCH must be set." >&2
        exit 1
    fi
    if [[ -z "${VERSION:-}" ]]; then
        echo "VERSION must be set." >&2
        exit 1
    fi
}

commit_and_push() {
    local msg
    # Clients cannot open backbone-core SHAs. Reuse core subject/body; insert [sync].
    msg="$(bash "${SCRIPT_DIR}/mirror-commit-message.sh" "${GITHUB_WORKSPACE}")"
    git commit -S -m "${msg}"
    git push origin "HEAD:${MIRROR_BRANCH}" || {
        git pull --rebase origin "${MIRROR_BRANCH}"
        git push origin "HEAD:${MIRROR_BRANCH}"
    }
}

tag_release_version() {
    local tag="v${VERSION}"
    if git rev-parse "${tag}^{commit}" > /dev/null 2>&1; then
        echo "Tag ${tag} already exists; skipped (do not move tags)."
        return 0
    fi
    git tag -s "${tag}" -m "chore(mirror): backbone-core ${VERSION}"
    git push origin "${tag}"
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_env

    git add -A
    if git diff --cached --quiet; then
        echo "No tree changes to mirror."
        exit 0
    fi

    commit_and_push
    tag_release_version
}

main "$@"
