#!/usr/bin/env bash
set -euo pipefail

# static-modules-changed.sh
# Type: executable
# Decide whether a push to main should deploy static UI assets (ui/ changes only).

# ---- Imports ----------------------------------------------------------------

readonly BEFORE_SHA="${GITHUB_EVENT_BEFORE}"
readonly AFTER_SHA="${GITHUB_SHA}"
readonly REPO_ROOT="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2> /dev/null || true)}"
# shellcheck source=../../scripts/lib/common.sh
source "${REPO_ROOT}/scripts/lib/common.sh"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli git
}

# ---- Main -------------------------------------------------------------------

main() {
    local -a changed_non_pom=()

    validate_dependencies

    echo "Push range: ${BEFORE_SHA} -> ${AFTER_SHA}"

    mapfile -t changed_non_pom < <(git diff --name-only "${BEFORE_SHA}" "${AFTER_SHA}" | grep -vE '(^|/)pom\.xml$' || true)

    if ((${#changed_non_pom[@]} == 0)); then
        echo "No non-pom changes in push; skipping deploy."
        echo "modules=" >> "${GITHUB_OUTPUT}"
        exit 0
    fi

    if printf '%s\n' "${changed_non_pom[@]}" | grep -qE '^ui/'; then
        echo "ui/ changed in push; deploying static assets."
        echo "modules=ui/web-actor" >> "${GITHUB_OUTPUT}"
        exit 0
    fi

    echo "No ui/ changes in push; skipping deploy."
    echo "modules=" >> "${GITHUB_OUTPUT}"
}

main "$@"
