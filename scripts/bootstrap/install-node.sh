#!/usr/bin/env bash
set -euo pipefail

# install-node.sh
# Type: executable
# Install Node from .nvmrc and set the default nvm alias.
# Invoked by install-toolchain-*.sh; not typically run directly.

# ---- Imports ----------------------------------------------------------------

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    # shellcheck source=scripts/bootstrap/nvm-env.sh
    source "${ROOT_DIR}/scripts/bootstrap/nvm-env.sh"
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_dependencies

    cd "$ROOT_DIR"
    nvm install
    nvm alias default "$(tr -d '[:space:]' < .nvmrc)"
    echo "Node $(node -v) installed; default alias set from .nvmrc"
}

main "$@"
