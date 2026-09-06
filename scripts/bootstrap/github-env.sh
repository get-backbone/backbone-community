#!/usr/bin/env bash
set -euo pipefail

# github-env.sh
# Type: executable
# Publishes matching GitHub Actions variables and secrets from .envrc.local.
# Does not re-prompt; run task bootstrap:dotenvrc first.
# Usage: task bootstrap:github-env

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/bootstrap/helpers.sh
source "${SCRIPT_DIR}/helpers.sh"
# shellcheck source=scripts/bootstrap/github-helpers.sh
source "${SCRIPT_DIR}/github-helpers.sh"

# ---- Constants --------------------------------------------------------------

readonly REQUIRED_SECRETS=(
    "NVD_API_KEY"
    "SMALLRYE_CONFIG_SECRET_KEY"
    "BACKBONE_OAUTH2_REFRESH_TOKEN_ENCRYPTION_KEY"
)
readonly OPTIONAL_GOOGLE_SECRETS=(
    "GOOGLE_OAUTH2_CLIENT_ID"
    "GOOGLE_OAUTH2_CLIENT_SECRET"
)
readonly OPTIONAL_LINKEDIN_SECRETS=(
    "LINKEDIN_OAUTH2_CLIENT_ID"
    "LINKEDIN_OAUTH2_CLIENT_SECRET"
)
readonly REQUIRED_VARIABLES=(
    "AWS_REGION"
)

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli gum
    require_cli gh
    require_cli yq
}

require_envrc_local() {
    if [[ ! -s "${ENVRC_FILE}" ]]; then
        log_error "Missing or empty ${ENVRC_FILE}"
        echo "Populate it first: task bootstrap:dotenvrc" >&2
        exit 1
    fi
}

load_envrc_local() {
    set -a
    # shellcheck disable=SC1090
    source "${ENVRC_FILE}"
    set +a
}

env_value() {
    local key="$1"
    printenv "${key}" 2> /dev/null || true
}

require_env_keys() {
    local key value
    for key in "$@"; do
        value="$(env_value "${key}")"
        if [[ -z "${value}" ]]; then
            log_error "${key} is empty in ${ENVRC_FILE}"
            echo "Re-run: task bootstrap:dotenvrc" >&2
            exit 1
        fi
    done
}

require_linkedin_when_enabled() {
    if [[ "$(platform_config_linkedin_oauth)" != "true" ]]; then
        return 0
    fi
    require_env_keys "${OPTIONAL_LINKEDIN_SECRETS[@]}"
}

require_google_when_enabled() {
    if [[ "$(platform_config_google_oauth)" != "true" ]]; then
        return 0
    fi
    require_env_keys "${OPTIONAL_GOOGLE_SECRETS[@]}"
}

collect_non_empty_keys() {
    local -n _out_keys="$1"
    shift
    local key value
    _out_keys=()
    for key in "$@"; do
        value="$(env_value "${key}")"
        if [[ -n "${value}" ]]; then
            _out_keys+=("${key}")
        fi
    done
}

confirm_publish() {
    local secret_repo="$1"
    shift
    local panel_lines=("Publish .envrc.local → GitHub Actions" "" "Repo: ${secret_repo}" "Source: ${ENVRC_FILE}" "" "Keys (values not shown):")
    local key
    for key in "$@"; do
        panel_lines+=("  • ${key}")
    done
    gum_panel "${GUM_PANEL_WIDTH}" "${panel_lines[@]}"
    if ! gum confirm "Set these Actions variables and secrets now?" --default=true; then
        log_info "Cancelled; no GitHub Actions values were changed."
        exit 0
    fi
}

publish_variables() {
    local secret_repo="$1"
    shift
    local key
    for key in "$@"; do
        publish_actions_variable "${key}" "$(env_value "${key}")" "${secret_repo}"
    done
}

publish_secrets() {
    local secret_repo="$1"
    shift
    local key
    for key in "$@"; do
        publish_actions_secret "${key}" "$(env_value "${key}")" "${secret_repo}"
    done
}

# ---- Main -------------------------------------------------------------------

main() {
    local secret_repo
    local variable_keys=()
    local secret_keys=()
    local optional_keys=()

    validate_dependencies
    require_envrc_local
    require_gh_auth
    load_envrc_local
    require_env_keys "${REQUIRED_VARIABLES[@]}" "${REQUIRED_SECRETS[@]}"
    require_google_when_enabled
    require_linkedin_when_enabled

    secret_repo="$(resolve_github_actions_repo)"
    collect_non_empty_keys variable_keys "${REQUIRED_VARIABLES[@]}"
    collect_non_empty_keys secret_keys "${REQUIRED_SECRETS[@]}"
    collect_non_empty_keys optional_keys "${OPTIONAL_GOOGLE_SECRETS[@]}" "${OPTIONAL_LINKEDIN_SECRETS[@]}"
    secret_keys+=("${optional_keys[@]}")

    confirm_publish "${secret_repo}" "${variable_keys[@]}" "${secret_keys[@]}"
    publish_variables "${secret_repo}" "${variable_keys[@]}"
    publish_secrets "${secret_repo}" "${secret_keys[@]}"
}

main "$@"
