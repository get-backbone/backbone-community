#!/usr/bin/env bash
set -euo pipefail

# template-helper.sh
# Type: executable
# Create a new bash script from template.sh (executable) or template-module.sh (source-only module).
# Usage: task bootstrap:script-template -- [--module] -- <path/to/script-name>

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/common.sh"

# ---- Constants --------------------------------------------------------------

readonly TEMPLATE_EXECUTABLE="${SCRIPT_DIR}/template.sh"
readonly TEMPLATE_MODULE="${SCRIPT_DIR}/template-module.sh"
readonly TARGET_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli sed
}

usage() {
    cat << EOF
Usage:
    $(basename "$0") [--module] -- <path/to/script-name>

Types:
    (default)   executable — task entrypoint or CLI script (template.sh)
    --module    source-only module — functions for other scripts (template-module.sh)

Examples:
    $(basename "$0") -- quarkus/port-manager
    $(basename "$0") --module aws/cognito/helpers
EOF
}

create_executable_script() {
    local script_path="$1"
    local script_name script_file

    script_name="$(basename "$script_path")"
    script_file="${TARGET_DIR}/${script_path}.sh"

    mkdir -p "$(dirname "$script_file")"

    if [[ -f "$script_file" ]]; then
        log_error "Script already exists: $script_file"
        exit 1
    fi

    sed "s|script-name.sh|${script_name}.sh|g; s|Description of what the script does|Add description here|g" \
        "$TEMPLATE_EXECUTABLE" > "$script_file"
    chmod +x "$script_file"
    echo "✅ Created executable script: $script_file"
}

create_module_script() {
    local script_path="$1"
    local script_name script_file

    script_name="$(basename "$script_path")"
    script_file="${TARGET_DIR}/${script_path}.sh"

    mkdir -p "$(dirname "$script_file")"

    if [[ -f "$script_file" ]]; then
        log_error "Script already exists: $script_file"
        exit 1
    fi

    sed "s|module-name.sh|${script_name}.sh|g; s|Description of shared functions for callers that source this file|Add description here|g" \
        "$TEMPLATE_MODULE" > "$script_file"
    chmod +x "$script_file"
    echo "✅ Created module script: $script_file"
}

# ---- Main -------------------------------------------------------------------

main() {
    local script_type="executable"
    local script_path=""

    validate_dependencies

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --module)
                script_type="module"
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                script_path="$1"
                shift
                break
                ;;
        esac
    done

    if [[ -z "$script_path" ]]; then
        usage
        exit 1
    fi

    if [[ "$script_type" == "module" ]]; then
        create_module_script "$script_path"
    else
        create_executable_script "$script_path"
    fi
}

main "$@"
