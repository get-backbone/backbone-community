#!/usr/bin/env bash
set -euo pipefail

# verify-licence.sh
# Type: executable
# Verifies a signed licence (signature and expiry) against the bundled public key
# in the licence/reactor JAR (META-INF/backbone-licence.pub). Prints JSON
# {clientId, tier, expiresAt} to stdout. Exits 0 if valid, 1 otherwise.
# Licence defaults to /etc/backbone-config/backbone-licence.
# Usage: task bootstrap:licence-verify [-- --licence <path>]

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli mvn
}

maven_pl() {
    # Core has libs/vendor/licence-runtime; mirrored clients only have libs (reactor dependency).
    if [[ -f "${ROOT_DIR}/libs/vendor/licence-runtime/pom.xml" ]]; then
        echo "libs/vendor/licence-runtime"
    else
        echo "libs"
    fi
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_dependencies

    cd "$ROOT_DIR"
    # JDK 25+: silence Guice/Maven sun.misc.Unsafe deprecation noise on Maven's JVM
    MAVEN_OPTS="${MAVEN_OPTS:-} --sun-misc-unsafe-memory-access=allow" \
        exec mvn exec:java \
        -q \
        -Dexec.mainClass="io.backbone.core.licence.cli.LicenceVerifier" \
        -pl "$(maven_pl)" \
        -Dexec.args="$*" \
        --no-transfer-progress
}

main "$@"
