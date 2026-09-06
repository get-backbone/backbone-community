#!/usr/bin/env bash
set -euo pipefail

# github-licence.sh
# Type: executable
# Publishes /etc/backbone-config/backbone-licence to GitHub Actions secret BACKBONE_LICENCE.
# Usage: task bootstrap:github-licence

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/bootstrap/github-helpers.sh
source "${SCRIPT_DIR}/github-helpers.sh"

# ---- Constants --------------------------------------------------------------

readonly LICENCE_FILE=/etc/backbone-config/backbone-licence

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli gum
    require_cli gh
    require_cli yq
}

require_licence_file() {
    if [[ ! -s "${LICENCE_FILE}" ]]; then
        log_error "Licence file missing: ${LICENCE_FILE}"
        echo "Install it first: task bootstrap:licence-install" >&2
        exit 1
    fi
}

# ---- Main -------------------------------------------------------------------

main() {
    local secret_repo

    validate_dependencies
    require_licence_file
    require_gh_auth

    gum_panel "${GUM_PANEL_WIDTH}" \
        "Publish licence to GitHub Actions" \
        "" \
        "Reads ${LICENCE_FILE}" \
        "Sets repository secret BACKBONE_LICENCE (hosted runners have no /etc path)."

    secret_repo="$(resolve_github_actions_repo)"
    publish_actions_secret BACKBONE_LICENCE "$(< "${LICENCE_FILE}")" "${secret_repo}"
}

main "$@"
