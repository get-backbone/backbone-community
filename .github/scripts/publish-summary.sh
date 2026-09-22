#!/usr/bin/env bash
set -euo pipefail

# publish-summary.sh
# Type: executable
# Generate GitHub Actions job summary for package publishing.

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../scripts/lib/common.sh
source "${SCRIPT_DIR}/../../scripts/lib/common.sh"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli jq
}

resolve_version() {
    local version
    version=$(jq -r '.client_payload.version // empty' "$GITHUB_EVENT_PATH")
    if [[ -n "$version" && "$version" != "null" ]]; then
        printf '%s\n' "$version"
        return
    fi
    if [[ -n "${PUBLISH_VERSION:-}" ]]; then
        printf '%s\n' "$PUBLISH_VERSION"
        return
    fi
    # workflow_dispatch / missing payload: version is whatever the checked-out pom says
    ./mvnw -q -DforceStdout help:evaluate -Dexpression=project.version
}

# ---- Main -------------------------------------------------------------------

main() {
    local version published=false
    local github_step_summary="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

    validate_dependencies

    version="$(resolve_version)"
    if [[ -n "$version" && "$version" != "null" ]]; then
        published=true
    fi

    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        {
            echo "version=${version}"
            echo "published=${published}"
        } >> "$GITHUB_OUTPUT"
    fi

    cat >> "$github_step_summary" << EOF
## 📦 Packages Published

**Version:** \`${version}\` (tag: \`v${version}\`)

Packages published to GitHub Package Registry.
EOF
}

main "$@"
