#!/usr/bin/env bash
set -euo pipefail

# version-bump-summary.sh
# Type: executable
# Generate GitHub Actions job summary for version bump status.
# Usage: ./version-bump-summary.sh [current_version] [bumped] [next_version]

# ---- Functions --------------------------------------------------------------

generate_summary() {
    local current_version="$1"
    local bumped="$2"
    local next_version="$3"
    local github_step_summary="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

    cat >> "$github_step_summary" << EOF
## 📦 Version Bump

**Current Version:** \`${current_version}\`
EOF

    if [ "$bumped" = "true" ]; then
        cat >> "$github_step_summary" << EOF

✅ **Version bumped:** \`${current_version}\` → \`${next_version}\`

Tag \`v${next_version}\` has been created and pushed.
EOF
    else
        cat >> "$github_step_summary" << EOF

ℹ️ **No version bump needed** - no eligible commits found.
EOF
    fi
}

# ---- Main -------------------------------------------------------------------

main() {
    local current_version="${CURRENT_VERSION:-${1:-}}"
    local bumped="${BUMPED:-${2:-false}}"
    local next_version="${NEXT_VERSION:-${3:-}}"

    generate_summary "$current_version" "$bumped" "$next_version"
}

main "$@"
