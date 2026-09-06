#!/usr/bin/env bash
# helpers.sh
# Type: module (source only — do not execute directly)
# Shared helpers for scripts/bootstrap (orchestrated by dotenvrc.sh).

# ---- Imports ----------------------------------------------------------------

if [[ -n "${_BACKBONE_BOOTSTRAP_HELPERS_LOADED:-}" ]]; then
    return 0
fi
_BACKBONE_BOOTSTRAP_HELPERS_LOADED=1

readonly _INIT_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${_INIT_HELPERS_DIR}/../lib/common.sh"

# ---- Constants --------------------------------------------------------------

readonly DOTENVRC_ROOT_DIR="$(cd "${_INIT_HELPERS_DIR}/../.." && pwd)"
readonly ENVRC_FILE="${ENVRC_FILE:-${DOTENVRC_ROOT_DIR}/.envrc.local}"
readonly PLATFORM_CONFIG_FILE="${PLATFORM_CONFIG_FILE:-${DOTENVRC_ROOT_DIR}/config/src/main/resources/platform-config.yml}"
readonly BACKBONE_OAUTH2_REFRESH_TOKEN_ENCRYPTION_KEY_NAME="BACKBONE_OAUTH2_REFRESH_TOKEN_ENCRYPTION_KEY"

# ---- Functions --------------------------------------------------------------

# Ensures ENVRC_FILE (.envrc.local) exists and is writable. Call once after sourcing this file.
dotenvrc_ensure_envrc_file() {
    touch "$ENVRC_FILE"
    if [[ ! -w "$ENVRC_FILE" ]]; then
        log_error "Cannot write to $ENVRC_FILE"
        return 1
    fi
}

# Prompts with gum until stdin yields a non-empty trimmed string (stdout). gum input has no --required.
# Args: $1 prompt, $2 optional default --value. Caller must ensure gum is on PATH.
gum_prompt_non_empty() {
    local prompt="$1"
    local default="${2:-}"
    local out=""
    while true; do
        out="$(gum input --prompt "$prompt" --value "$default")"
        out="$(xargs <<< "$out" || true)"
        [[ -n "$out" ]] && {
            echo "$out"
            return 0
        }
        log_error "Value cannot be empty — please enter a non-empty value."
    done
}

# Returns 0 if the key is already set in the environment (non-empty) or present in .envrc.local as
# export KEY="non-empty-value". Safe with set -u (no indirect expansion of unset names).
dotenvrc_key_is_configured() {
    local key="$1"
    local v
    v=$(printenv "$key" 2> /dev/null || true)
    if [[ -n "$v" ]]; then
        return 0
    fi
    [[ -f "$ENVRC_FILE" ]] || return 1
    grep -qE "^export ${key}=\"[^\"]+\"" "$ENVRC_FILE" 2> /dev/null
}

# Generates a base64-encoded encryption key from a raw key using jbang
# Args:
#   $1: raw encryption key
# Returns: base64-encoded key on stdout, or returns 1 on error
get_base64_encoded_key() {
    local raw_key=$1

    jbang https://raw.githubusercontent.com/smallrye/smallrye-config/main/documentation/src/main/docs/config/secret-handlers/encryptor.java \
        -s="dummy" \
        -k="$raw_key" |
        grep '^smallrye.config.secret-handler.aes-gcm-nopadding.encryption-key=' |
        cut -d'=' -f2
}

# Auto-generates BACKBONE_OAUTH2_REFRESH_TOKEN_ENCRYPTION_KEY when missing (Cognito + optional IdP flows).
# Requires openssl on PATH.
ensure_refresh_token_encryption_key() {
    local generated_key
    if dotenvrc_key_is_configured "$BACKBONE_OAUTH2_REFRESH_TOKEN_ENCRYPTION_KEY_NAME"; then
        return 0
    fi

    require_cli openssl
    generated_key="$(openssl rand -base64 32)"
    update_envrc_key "$BACKBONE_OAUTH2_REFRESH_TOKEN_ENCRYPTION_KEY_NAME" "$generated_key"
    echo "✅ Generated and updated $BACKBONE_OAUTH2_REFRESH_TOKEN_ENCRYPTION_KEY_NAME in .envrc.local"
}

# Reads top-level linkedInOauthEnabled from platform-config.yml (required boolean).
# Returns "true" or "false" on stdout.
platform_config_linkedin_oauth() {
    local value
    value=$(
        awk '$1 == "linkedInOauthEnabled:" { print $2; exit }' "$PLATFORM_CONFIG_FILE"
    )

    printf '%s\n' "${value:-false}"
}

# Reads top-level googleOauthEnabled from platform-config.yml (required boolean).
# Returns "true" or "false" on stdout.
platform_config_google_oauth() {
    local value
    value=$(
        awk '$1 == "googleOauthEnabled:" { print $2; exit }' "$PLATFORM_CONFIG_FILE"
    )

    printf '%s\n' "${value:-false}"
}
