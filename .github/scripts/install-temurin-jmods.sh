#!/usr/bin/env bash
set -euo pipefail

# install-temurin-jmods.sh
# Type: executable
# Install Eclipse Temurin JMOD archives into $JAVA_HOME/jmods.
# Temurin 24+ ships without jmods (JEP 493); ProGuard and similar tools still need them.
# See: https://adoptium.net/news/2025/03/eclipse-temurin-jdk24-JEP493-enabled/
# Usage: ./install-temurin-jmods.sh
# Requires: JAVA_HOME, curl, tar; no gum/task (may run in parallel with shell-tools).

# ---- Constants --------------------------------------------------------------

readonly ADOPTIUM_PROJECT='jdk'
readonly ADOPTIUM_JVM_IMPL='hotspot'
readonly ADOPTIUM_HEAP_SIZE='normal'
readonly ADOPTIUM_VENDOR='eclipse'

# ---- Functions --------------------------------------------------------------

require_java_home() {
    if [[ -z "${JAVA_HOME:-}" ]]; then
        echo "JAVA_HOME must be set before installing Temurin jmods." >&2
        exit 1
    fi
    if [[ ! -d "${JAVA_HOME}" ]]; then
        echo "JAVA_HOME does not exist: ${JAVA_HOME}" >&2
        exit 1
    fi
}

jmods_already_present() {
    [[ -f "${JAVA_HOME}/jmods/java.base.jmod" ]]
}

java_major_version() {
    # e.g. openjdk version "25.0.3" … or java version "25" …
    java -version 2>&1 | awk -F '"' '/version/ { print $2; exit }' | cut -d. -f1
}

adoptium_arch() {
    case "$(uname -m)" in
        x86_64 | amd64) echo x64 ;;
        aarch64 | arm64) echo aarch64 ;;
        *)
            echo "Unsupported architecture for Temurin jmods: $(uname -m)" >&2
            exit 1
            ;;
    esac
}

download_and_install_jmods() {
    local java_major arch url tmp_dir archive

    java_major="$(java_major_version)"
    if [[ -z "${java_major}" ]]; then
        echo "Could not determine Java major version from java -version." >&2
        exit 1
    fi

    arch="$(adoptium_arch)"
    url="https://api.adoptium.net/v3/binary/latest/${java_major}/ga/linux/${arch}/jmods/${ADOPTIUM_JVM_IMPL}/${ADOPTIUM_HEAP_SIZE}/${ADOPTIUM_VENDOR}?project=${ADOPTIUM_PROJECT}"

    tmp_dir="$(mktemp -d)"
    # Expand path now: tmp_dir is local and gone when EXIT fires after the function returns (set -u).
    # shellcheck disable=SC2064
    trap "rm -rf '${tmp_dir}'" EXIT

    echo "Downloading Temurin ${java_major} jmods (${arch}) into ${JAVA_HOME}/jmods"
    archive="${tmp_dir}/temurin-jmods.tar.gz"
    curl -fsSL --retry 3 --retry-delay 2 -A 'backbone-core-ci' -o "${archive}" "${url}"

    tar -xzf "${archive}" -C "${tmp_dir}"
    mkdir -p "${JAVA_HOME}/jmods"
    # Archive layout is typically jdk-<ver>-jmods/*.jmod — copy flat into JAVA_HOME/jmods.
    find "${tmp_dir}" -type f -name '*.jmod' -exec cp -f {} "${JAVA_HOME}/jmods/" \;

    if [[ ! -f "${JAVA_HOME}/jmods/java.base.jmod" ]]; then
        echo "Temurin jmods install failed: java.base.jmod missing under ${JAVA_HOME}/jmods" >&2
        exit 1
    fi

    echo "Installed $(find "${JAVA_HOME}/jmods" -name '*.jmod' | wc -l | tr -d ' ') jmod files"

    rm -rf "${tmp_dir}"
    trap - EXIT
}

# ---- Main -------------------------------------------------------------------

main() {
    require_java_home

    if jmods_already_present; then
        echo "JMODs already present at ${JAVA_HOME}/jmods — skipping download"
        exit 0
    fi

    download_and_install_jmods
}

main "$@"
