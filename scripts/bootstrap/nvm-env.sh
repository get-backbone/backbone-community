#!/usr/bin/env bash
# nvm-env.sh
# Type: module (source to load nvm, or exec as wrapper: nvm-env.sh <command> [args...])
# Load nvm for bootstrap scripts and infra Task tasks.

# ---- Functions --------------------------------------------------------------

load_nvm() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    mkdir -p "$NVM_DIR"

    if [ -s "${NVM_DIR}/nvm.sh" ]; then
        # shellcheck disable=SC1091
        . "${NVM_DIR}/nvm.sh"
        return 0
    fi

    if command -v brew > /dev/null 2>&1; then
        local_brew_nvm="$(brew --prefix nvm 2> /dev/null)/nvm.sh"
        if [ -s "$local_brew_nvm" ]; then
            # shellcheck disable=SC1090,SC1091
            . "$local_brew_nvm"
            return 0
        fi
    fi

    echo "nvm is not available. Run: task bootstrap:toolchain" >&2
    return 1
}

# ---- Exec wrapper (when run directly, not sourced) ---------------------------

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    load_nvm
    return
fi

set -euo pipefail

if [ "$#" -eq 0 ]; then
    echo "usage: $(basename "$0") <command> [args...]" >&2
    exit 1
fi

load_nvm
nvm use
exec "$@"
