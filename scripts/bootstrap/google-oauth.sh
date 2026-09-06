#!/usr/bin/env bash
set -euo pipefail

# google-oauth.sh
# Type: executable
# Google OAuth keys → .envrc.local when googleOauthEnabled is true in platform-config.
# Invoked by dotenvrc.sh.

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/bootstrap/helpers.sh
source "$SCRIPT_DIR/helpers.sh"

# ---- Constants --------------------------------------------------------------

readonly ENVRC_KEYS=(
    "GOOGLE_OAUTH2_CLIENT_ID"
    "GOOGLE_OAUTH2_CLIENT_SECRET"
)

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli gum
}

# ---- Main -------------------------------------------------------------------

main() {
    local google_oauth_enabled key new_value

    validate_dependencies
    dotenvrc_ensure_envrc_file
    ensure_refresh_token_encryption_key

    google_oauth_enabled="$(platform_config_google_oauth)"
    if [[ "$google_oauth_enabled" != "true" ]]; then
        gum style --faint "Google OAuth disabled in platform-config (googleOauthEnabled: false); skipping client credentials."
        return 0
    fi

    gum_panel 60 "Update .envrc.local with Google OAuth keys."

    gum style --faint "📖 References:"
    gum style --faint "  • Google Cloud Console: https://console.cloud.google.com/apis/credentials"

    for key in "${ENVRC_KEYS[@]}"; do
        if dotenvrc_key_is_configured "$key"; then
            continue
        fi

        new_value=$(gum input --prompt "Enter value for $key:" --password)

        if [[ -z "$new_value" ]]; then
            log_error "$key cannot be empty."
            exit 1
        fi

        update_envrc_key "$key" "$new_value"
        echo "✅ Updated $key in .envrc.local"
    done
}

main "$@"
