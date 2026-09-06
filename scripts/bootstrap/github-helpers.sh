#!/usr/bin/env bash
# github-helpers.sh
# Type: module (source only — do not execute directly)
# Shared GitHub CLI helpers for bootstrap:github-* scripts.

# ---- Imports ----------------------------------------------------------------

if [[ -n "${_BACKBONE_GITHUB_HELPERS_LOADED:-}" ]]; then
    return 0
fi
_BACKBONE_GITHUB_HELPERS_LOADED=1

readonly _GITHUB_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${_GITHUB_HELPERS_DIR}/../lib/common.sh"

# ---- Constants --------------------------------------------------------------

readonly GITHUB_HELPERS_REPO_ROOT="$(cd "${_GITHUB_HELPERS_DIR}/../.." && pwd)"
: "${PLATFORM_CONFIG_FILE:=${GITHUB_HELPERS_REPO_ROOT}/config/src/main/resources/platform-config.yml}"

# ---- Functions --------------------------------------------------------------

require_gh_auth() {
    if gh auth status > /dev/null 2>&1; then
        return 0
    fi
    log_error "gh is not authenticated. Run: gh auth login"
    exit 1
}

config_github_field() {
    local field="$1"
    yq eval -r ".github.${field} // \"\"" "${PLATFORM_CONFIG_FILE}" 2> /dev/null || echo ""
}

trim_whitespace() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s\n' "${value}"
}

# Resolves owner/repo for Actions secrets and variables from platform-config.yml,
# falling back to the current gh checkout.
resolve_github_actions_repo() {
    local organization repo
    organization="$(trim_whitespace "$(config_github_field organization)")"
    repo="$(trim_whitespace "$(config_github_field repo)")"
    if [[ -n "${organization}" && -n "${repo}" ]]; then
        printf '%s/%s\n' "${organization}" "${repo}"
        return 0
    fi
    gh repo view --json nameWithOwner --jq .nameWithOwner
}

publish_actions_secret() {
    local name="$1"
    local value="$2"
    local secret_repo="$3"
    gh secret set "${name}" --repo "${secret_repo}" --body "${value}"
}

publish_actions_variable() {
    local name="$1"
    local value="$2"
    local secret_repo="$3"
    gh variable set "${name}" --repo "${secret_repo}" --body "${value}"
}
