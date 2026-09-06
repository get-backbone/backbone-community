#!/usr/bin/env bash
set -euo pipefail

# install-sdkman-tools.sh
# Type: executable
# Installs SDKMAN when missing, then Java (Graal) and Maven Daemon.
# Invoked by task bootstrap:toolchain before OS-specific install scripts.

# ---- Constants --------------------------------------------------------------

readonly SDKMAN_INIT="${HOME}/.sdkman/bin/sdkman-init.sh"

# ---- Functions --------------------------------------------------------------

# ---- Main -------------------------------------------------------------------

main() {
    export SDKMAN_AUTO_ANSWER=true

    if [[ ! -s "${SDKMAN_INIT}" ]]; then
        curl -s "https://get.sdkman.io" | bash
    fi

    # shellcheck disable=SC1091
    source "${SDKMAN_INIT}"

    sdk install java 25-graal
    sdk install mvnd
}

main "$@"
