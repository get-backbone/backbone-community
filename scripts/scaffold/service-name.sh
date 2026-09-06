#!/usr/bin/env bash
# service-name.sh
# Type: module (source only — do not execute directly)
# Derives platform naming tokens from a kebab-case service module name.

# ---- Imports ----------------------------------------------------------------

readonly MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${MODULE_DIR}/../lib/common.sh"

# ---- Functions --------------------------------------------------------------

# Returns 0 if name is valid kebab-case (lowercase letters, digits, hyphens; no leading/trailing hyphen).
is_valid_service_name() {
    local name="$1"
    [[ "$name" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]
}

# PascalCase each hyphen-separated segment: quote-engine -> QuoteEngine
to_pascal_case() {
    local input="$1"
    local result="" segment
    local IFS='-'
    # shellcheck disable=SC2086
    for segment in $input; do
        result+="$(printf '%s' "${segment:0:1}" | tr '[:lower:]' '[:upper:]')"
        result+="${segment:1}"
    done
    printf '%s' "$result"
}

# Title Case with spaces: quote-engine -> Quote Engine
to_display_name() {
    local input="$1"
    local result="" segment
    local IFS='-'
    # shellcheck disable=SC2086
    for segment in $input; do
        if [[ -n "$result" ]]; then
            result+=" "
        fi
        result+="$(printf '%s' "${segment:0:1}" | tr '[:lower:]' '[:upper:]')"
        result+="${segment:1}"
    done
    printf '%s' "$result"
}

# Derives naming tokens from SERVICE_NAME into caller-visible variables:
#   SERVICE_NAME, PACKAGE_SEGMENT, CLASS_PREFIX, ENV_PREFIX, PORT_VAR,
#   ALB_INTERNAL_PATH, TASK_ALIAS, DISPLAY_NAME
# shellcheck disable=SC2034 # exported for callers that source this module
derive_service_names() {
    local service_name="$1"
    local base_for_package

    if [[ -z "$service_name" ]]; then
        log_error "Service name is required"
        return 1
    fi

    if ! is_valid_service_name "$service_name"; then
        log_error "Invalid service name '${service_name}'. Use kebab-case (e.g. quote-engine, search-service)."
        return 1
    fi

    SERVICE_NAME="$service_name"

    if [[ "$service_name" == *-service ]]; then
        base_for_class="${service_name%-service}"
        TASK_ALIAS="${service_name%-service}"
        # actor-service -> actor; user-profile-service -> userprofile
        PACKAGE_SEGMENT="${base_for_class//-/}"
    else
        # quote-engine -> package/alias quote, class QuoteEngine
        base_for_class="$service_name"
        PACKAGE_SEGMENT="${service_name%%-*}"
        TASK_ALIAS="$PACKAGE_SEGMENT"
    fi

    CLASS_PREFIX="$(to_pascal_case "$base_for_class")"
    ENV_PREFIX="$(printf '%s' "$service_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
    PORT_VAR="${ENV_PREFIX}_PORT"
    ALB_INTERNAL_PATH="/${PACKAGE_SEGMENT}/*"
    DISPLAY_NAME="$(to_display_name "$service_name")"
}
