#!/usr/bin/env bash
set -euo pipefail

# script-name.sh
# Type: executable
# Description of what the script does.
# Usage: task namespace:task   OR   ./script-name.sh [args]

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# ---- Constants --------------------------------------------------------------

# readonly literals only; derived paths belong in main()

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli gum
    # require_cli other-cli
}

# Omit usage() when the script is task-only with no CLI arguments.
usage() {
    cat << EOF
Usage:
    $(basename "$0") [args]

Examples:
    $(basename "$0")
EOF
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_dependencies

    # implementation
}

main "$@"
