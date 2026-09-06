#!/usr/bin/env bash
set -euo pipefail

# secrets.sh
# Type: executable
# SmallRye Config encryption key → .envrc.local (auto-generated; no prompt).
# Invoked by dotenvrc.sh. Retains support for Quarkus secrets.properties encryption.

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/bootstrap/helpers.sh
source "$SCRIPT_DIR/helpers.sh"

# ---- Constants --------------------------------------------------------------

readonly SMALLRYE_CONFIG_KEY_NAME="SMALLRYE_CONFIG_SECRET_KEY"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli openssl
    require_cli jbang
}

ensure_smallrye_config_secret_key() {
    local raw_key base64_key

    if dotenvrc_key_is_configured "$SMALLRYE_CONFIG_KEY_NAME"; then
        return 0
    fi

    # openssl material → SmallRye encryptor normalizes to the base64 property value Quarkus expects
    raw_key="$(openssl rand -base64 32)"
    base64_key="$(get_base64_encoded_key "$raw_key")"

    if [[ -z "$base64_key" ]]; then
        log_error "Failed to generate SmallRye Config encryption key"
        exit 1
    fi

    update_envrc_key "$SMALLRYE_CONFIG_KEY_NAME" "$base64_key"
    echo "✅ Generated and updated $SMALLRYE_CONFIG_KEY_NAME in .envrc.local"
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_dependencies
    dotenvrc_ensure_envrc_file
    ensure_smallrye_config_secret_key
}

main "$@"
