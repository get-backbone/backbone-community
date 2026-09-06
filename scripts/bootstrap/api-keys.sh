#!/usr/bin/env bash
set -euo pipefail

# api-keys.sh
# Type: executable
# Third-party API keys → .envrc. Invoked by dotenvrc.sh; use task bootstrap:dotenvrc.

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/bootstrap/helpers.sh
source "$SCRIPT_DIR/helpers.sh"

# ---- Constants --------------------------------------------------------------

readonly ENVRC_KEYS=(
    "NVD_API_KEY"
)

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli gum
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_dependencies
    dotenvrc_ensure_envrc_file

    gum_panel 60 "Update .envrc.local with 3rd party API keys."

    gum style --faint "📖 References:"
    gum style --faint "  • NVD: https://nvd.nist.gov/developers/request-an-api-key"
    gum style --faint "  • Sonatype Guide / OSS Index: CI secrets only (weekly OWASP) — https://guide.sonatype.com/"

    local key new_value
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
