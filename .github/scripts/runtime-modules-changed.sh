#!/usr/bin/env bash
set -euo pipefail

# runtime-modules-changed.sh
# Type: executable
# Detect changed ECS deployable modules between the previous release tag and HEAD.

# ---- Imports ----------------------------------------------------------------

readonly HEAD_SHA="${GITHUB_SHA:-}"
readonly REPO_ROOT="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2> /dev/null || true)}"
# shellcheck source=../../scripts/lib/common.sh
source "${REPO_ROOT}/scripts/lib/common.sh"

readonly SERVICES_JSON="${REPO_ROOT}/infra/src/lib/constant/backbone-services.json"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli git
    require_cli jq
}

# ---- Main -------------------------------------------------------------------

main() {
    local parent_sha prev_tag base_sha
    local -a changed_non_pom=() ecs_module_paths=() modules=()

    validate_dependencies

    if [[ -z "${HEAD_SHA}" ]]; then
        echo "HEAD SHA is not set (GITHUB_SHA)."
        exit 1
    fi

    parent_sha="$(git rev-parse "${HEAD_SHA}^")"
    prev_tag="$(git describe --tags --abbrev=0 "${parent_sha}")"
    base_sha="$(git rev-list -n 1 "${prev_tag}")"

    echo "Head: ${HEAD_SHA}"
    echo "Parent of head: ${parent_sha}"
    echo "Previous release tag: ${prev_tag} -> ${base_sha}"

    mapfile -t changed_non_pom < <(git diff --name-only "${base_sha}" "${HEAD_SHA}" | grep -vE '(^|/)pom\.xml$' || true)
    if ((${#changed_non_pom[@]} > 0)); then
        echo "Changed paths (excluding pom.xml): ${#changed_non_pom[@]} file(s)"
    fi

    mapfile -t ecs_module_paths < <(jq -r '.services[] | select(.deployment == "ecs") | .modulePath' "${SERVICES_JSON}" | sort -u)

    if ((${#changed_non_pom[@]} > 0)) && printf '%s\n' "${changed_non_pom[@]}" | grep -qE '^(core|config)/'; then
        echo "core/ or config/ changed in range (non-pom); rebuilding all ECS modules."
        mapfile -t modules < <(printf '%s\n' "${ecs_module_paths[@]}" | sort -u)
    else
        mapfile -t modules < <(
            comm -12 \
                <(printf '%s\n' "${changed_non_pom[@]}" |
                    grep -E '^(services|applications)/' |
                    awk -F/ '{print $1"/"$2}' |
                    sort -u) \
                <(printf '%s\n' "${ecs_module_paths[@]}" | sort -u)
        )
    fi

    if ((${#modules[@]} == 0)); then
        echo "No ECS deployable modules changed."
        echo "modules=" >> "${GITHUB_OUTPUT}"
        exit 0
    fi

    printf 'Changed ECS modules:\n%s\n' "${modules[@]}"
    echo "modules=${modules[*]}" >> "${GITHUB_OUTPUT}"
}

main "$@"
