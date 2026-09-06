#!/usr/bin/env bash
set -euo pipefail

# publish-summary.sh
# Type: executable
# Generate GitHub Actions job summary for package publishing.

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=../../scripts/lib/common.sh
source "${REPO_ROOT}/scripts/lib/common.sh"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli jq
}

# ---- Main -------------------------------------------------------------------

main() {
    local version published=false
    local github_step_summary="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

    validate_dependencies

    version=$(jq -r '.client_payload.version' "$GITHUB_EVENT_PATH")

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
