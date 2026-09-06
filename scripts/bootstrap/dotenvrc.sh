#!/usr/bin/env bash
set -euo pipefail

# dotenvrc.sh
# Type: executable
# Main entry: wires .envrc.local for local dev (API keys, encryption keys).
# Node.js for CDK is scoped to infra/ (see infra/.envrc and scripts/bootstrap/nvm-env.sh).
# Usage: task bootstrap:dotenvrc

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/bootstrap/helpers.sh
source "$SCRIPT_DIR/helpers.sh"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli gum
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_dependencies
    dotenvrc_ensure_envrc_file

    local aws_region

    gum_panel 60 \
        "Initialize .envrc.local" \
        "" \
        "This will set up:" \
        "  • AWS_PROFILE / AWS_REGION for local Quarkus + SDK" \
        "  • External API keys (NVD)" \
        "  • OAuth2 keys when enabled (Google, LinkedIn)" \
        "  • Auto-generated encryption keys (OAuth refresh, SmallRye Config)" \
        "" \
        "> direnv loads .envrc.local (secrets). Changes reload automatically via watch_file."

    update_envrc_key "AWS_PROFILE" "backbone-sandbox"
    aws_region="$(gum_prompt_non_empty "AWS_REGION: " "${AWS_REGION:-us-west-2}")"
    update_envrc_key "AWS_REGION" "$aws_region"
    remove_envrc_key "BACKBONE_LICENCE"
    remove_envrc_key "BACKBONE_LICENCE_TIER"

    "$SCRIPT_DIR/api-keys.sh"
    "$SCRIPT_DIR/google-oauth.sh"
    "$SCRIPT_DIR/linkedin-oauth.sh"
    "$SCRIPT_DIR/secrets.sh"

    echo
    gum style --bold "✅ .envrc.local updated. direnv will reload on the next prompt (or run: direnv reload)."
}

main "$@"
