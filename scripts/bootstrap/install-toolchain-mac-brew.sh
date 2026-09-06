#!/usr/bin/env bash
set -euo pipefail

# install-toolchain-mac-brew.sh
# Type: executable
# Installs the Backbone developer CLI toolchain on macOS via Homebrew.
# Usage: task bootstrap:toolchain (Darwin). SDKMAN runs before this script.

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

readonly ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ---- Functions --------------------------------------------------------------

require_brew() {
    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew is required but not installed." >&2
        echo "Install from https://brew.sh" >&2
        exit 1
    fi
}

validate_dependencies() {
    require_brew
}

install_brew_formulae() {
    brew install \
        direnv \
        jbang \
        shellcheck \
        gettext \
        jq \
        gum \
        gh \
        yq \
        lefthook \
        pwgen \
        openssl \
        quarkusio/tap/quarkus \
        markdownlint-cli2 \
        moreutils \
        trufflehog \
        yamllint \
        shfmt \
        k6 \
        awscli \
        awscli-local \
        nvm
}

install_node_and_npm_globals() {
    bash "$ROOT_DIR/scripts/bootstrap/install-node.sh"
    bash -c "source \"$ROOT_DIR/scripts/bootstrap/nvm-env.sh\" && npm install -g mert"
}

install_orbstack() {
    brew install --cask --adopt orbstack
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_dependencies
    install_brew_formulae
    install_node_and_npm_globals
    install_orbstack
    log_info "macOS toolchain install complete."
}

main "$@"
