#!/usr/bin/env bash
set -euo pipefail

# install-toolchain-amzn-linux.sh
# Type: executable
# Installs the Backbone developer CLI toolchain on Amazon Linux (AL2023 / AL2) via dnf/yum.
# Usage: task bootstrap:toolchain (Linux). SDKMAN runs before this script.

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

readonly ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ---- Constants --------------------------------------------------------------

PKG_MGR=""
LINUX_ARCH=""
readonly YQ_VERSION="v4.44.6"
readonly SHFMT_VERSION="3.10.0"
readonly NVM_INSTALL_VERSION="v0.40.2"
readonly COMMITIZEN_VERSION="4.13.7"

# ---- Functions --------------------------------------------------------------
require_amazon_linux() {
    if [[ "$(uname -s)" != "Linux" ]]; then
        echo "Error: Amazon Linux toolchain install requires Linux." >&2
        exit 1
    fi

    if [[ ! -f /etc/os-release ]]; then
        echo "Error: /etc/os-release not found." >&2
        exit 1
    fi

    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" != "amzn" ]]; then
        echo "Error: Amazon Linux only (ID=${ID:-unknown}). task bootstrap:toolchain supports macOS and Amazon Linux AL2023 / AL2." >&2
        exit 1
    fi

    if command -v dnf &> /dev/null; then
        PKG_MGR=dnf
    elif command -v yum &> /dev/null; then
        PKG_MGR=yum
    else
        echo "Error: dnf or yum is required." >&2
        exit 1
    fi

    LINUX_ARCH="$(uname -m)"
}

validate_dependencies() {
    require_amazon_linux
}

run_pkg_install() {
    sudo "${PKG_MGR}" install -y "$@"
}

install_optional_pkg() {
    local pkg=$1
    if sudo "${PKG_MGR}" install -y "${pkg}"; then
        return 0
    fi
    log_warn "${pkg} not available via ${PKG_MGR}; install manually if needed."
}

ensure_charm_repo() {
    if [[ -f /etc/yum.repos.d/charm.repo ]]; then
        return 0
    fi

    sudo rpm --import https://repo.charm.sh/yum/gpg.key
    sudo tee /etc/yum.repos.d/charm.repo > /dev/null << 'CHARM_REPO'
[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key
CHARM_REPO
}

install_base_packages() {
    run_pkg_install \
        git \
        jq \
        gettext \
        openssl \
        awscli \
        python3-pip \
        docker

    ensure_charm_repo
    run_pkg_install gum pwgen

    install_optional_pkg moreutils
    install_optional_pkg shellcheck
    install_optional_pkg docker-compose-plugin
}

install_k6() {
    if command -v k6 &> /dev/null; then
        return 0
    fi

    run_pkg_install https://dl.k6.io/rpm/repo.rpm
    run_pkg_install k6
}

install_gh() {
    if command -v gh &> /dev/null; then
        return 0
    fi

    if [[ "${PKG_MGR}" == "dnf" ]]; then
        run_pkg_install 'dnf-command(config-manager)'
        sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo dnf install -y gh
        return 0
    fi

    if ! type -p yum-config-manager > /dev/null; then
        run_pkg_install yum-utils
    fi
    sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    run_pkg_install gh
}

install_task_if_missing() {
    if command -v task &> /dev/null; then
        return 0
    fi

    sh -c "$(curl -fsSL https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
}

install_jbang() {
    if command -v jbang &> /dev/null; then
        return 0
    fi

    curl -Ls https://sh.jbang.dev | bash
}

jbang_bin_dir() {
    printf '%s/.jbang/bin' "${HOME}"
}

install_quarkus_cli() {
    local jbang_bin
    jbang_bin="$(jbang_bin_dir)"
    export PATH="${jbang_bin}:${PATH}"

    curl -Ls https://sh.jbang.dev | bash -s - trust add https://repo1.maven.org/maven2/io/quarkus/quarkus-cli/
    curl -Ls https://sh.jbang.dev | bash -s - app install --fresh --force quarkus@quarkusio
}

install_lefthook() {
    if command -v lefthook &> /dev/null; then
        return 0
    fi

    curl -1sLf 'https://dl.cloudsmith.io/public/evilmartians/lefthook/setup.rpm.sh' | sudo -E bash
    run_pkg_install lefthook
}

install_trufflehog() {
    if command -v trufflehog &> /dev/null; then
        return 0
    fi

    curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh |
        sh -s -- -b /usr/local/bin
}

binary_arch_suffix() {
    case "${LINUX_ARCH}" in
        x86_64) echo amd64 ;;
        aarch64) echo arm64 ;;
        *)
            log_error "Unsupported architecture: ${LINUX_ARCH}"
            exit 1
            ;;
    esac
}

install_yq() {
    if command -v yq &> /dev/null; then
        return 0
    fi

    local arch url
    arch="$(binary_arch_suffix)"
    url="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${arch}"
    sudo curl -fsSL "${url}" -o /usr/local/bin/yq
    sudo chmod +x /usr/local/bin/yq
}

install_shfmt() {
    if command -v shfmt &> /dev/null; then
        return 0
    fi

    local arch url
    arch="$(binary_arch_suffix)"
    url="https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_${arch}"
    curl -fsSL "${url}" -o /tmp/shfmt
    sudo install -m 755 /tmp/shfmt /usr/local/bin/shfmt
    rm -f /tmp/shfmt
}

install_direnv() {
    if command -v direnv &> /dev/null; then
        return 0
    fi

    curl -sfL https://direnv.net/install.sh | bash
}

install_python_cli_tools() {
    python3 -m pip install --user --quiet \
        "commitizen==${COMMITIZEN_VERSION}" \
        awscli-local \
        yamllint
}

install_nvm_if_missing() {
    export NVM_DIR="${NVM_DIR:-${HOME}/.nvm}"
    if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
        return 0
    fi

    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_INSTALL_VERSION}/install.sh" | bash
}

install_node_and_npm_globals() {
    bash "${ROOT_DIR}/scripts/bootstrap/install-node.sh"
    bash -c "source \"${ROOT_DIR}/scripts/bootstrap/nvm-env.sh\" && npm install -g markdownlint-cli2 mert"
}

enable_docker() {
    sudo systemctl enable --now docker
    if ! id -nG "$(whoami)" | grep -qw docker; then
        sudo usermod -aG docker "$(whoami)"
        log_warn "Added $(whoami) to the docker group. Log out and back in before running docker without sudo."
    fi
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_dependencies
    install_base_packages
    install_k6
    install_gh
    install_task_if_missing
    install_jbang
    install_quarkus_cli
    install_lefthook
    install_trufflehog
    install_yq
    install_shfmt
    install_direnv
    install_python_cli_tools
    install_nvm_if_missing
    install_node_and_npm_globals
    enable_docker

    log_info "Amazon Linux toolchain install complete."
    log_info "Restart your shell (or source ~/.bashrc) so PATH picks up jbang, direnv, nvm, and pip user bins."
}

main "$@"
