#!/usr/bin/env bash
set -euo pipefail

# check-container-privilege-posture.sh
# Type: executable
# Fail CI when Dockerfiles run as root or infra enables privileged / host-network ECS settings.

# ---- Imports ----------------------------------------------------------------

readonly REPO_ROOT="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2> /dev/null || true)}"
if [[ -z "${REPO_ROOT}" ]]; then
    echo "Unable to resolve repository root." >&2
    exit 1
fi

# ---- Functions --------------------------------------------------------------

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_dockerfile_non_root() {
    local dockerfile="$1"
    local last_user=""
    local line

    while IFS= read -r line || [[ -n "${line}" ]]; do
        # Strip comments and trailing whitespace for USER matching.
        line="${line%%#*}"
        line="${line%"${line##*[![:space:]]}"}"
        if [[ "${line}" =~ ^[Uu][Ss][Ee][Rr][[:space:]]+(.+)$ ]]; then
            last_user="${BASH_REMATCH[1]}"
            last_user="${last_user#"${last_user%%[![:space:]]*}"}"
            last_user="${last_user%"${last_user##*[![:space:]]}"}"
        fi
    done < "${dockerfile}"

    if [[ -z "${last_user}" ]]; then
        fail "${dockerfile}: final stage must declare a non-root USER"
    fi

    case "${last_user}" in
        root | 0 | root:root | 0:0 | root:0 | 0:root)
            fail "${dockerfile}: final USER must not be root (found '${last_user}')"
            ;;
    esac

    echo "OK: ${dockerfile} final USER=${last_user}"
}

assert_no_privileged_true() {
    local matches

    matches="$(
        grep -RInE --include='*.ts' --include='*.js' --include='*.json' --include='*.yml' --include='*.yaml' \
            '(^|[^A-Za-z0-9_])privileged[[:space:]]*:[[:space:]]*true([^A-Za-z0-9_]|$)' \
            "${REPO_ROOT}/infra/src" "${REPO_ROOT}/infra/test" 2> /dev/null || true
    )"

    if [[ -n "${matches}" ]]; then
        echo "${matches}" >&2
        fail "privileged: true is not allowed in infra sources (Fargate does not support privileged mode)"
    fi

    echo "OK: no privileged: true in infra sources"
}

assert_no_host_network_mode() {
    local matches

    matches="$(
        grep -RInE --include='*.ts' --include='*.js' --include='*.json' --include='*.yml' --include='*.yaml' \
            'NetworkMode\.HOST|networkMode:[[:space:]]*['\''\"]host['\''\"]|NetworkMode:[[:space:]]*['\''\"]host['\''\"]' \
            "${REPO_ROOT}/infra/src" 2> /dev/null || true
    )"

    if [[ -n "${matches}" ]]; then
        echo "${matches}" >&2
        fail "host networking is not allowed for Backbone ECS task definitions"
    fi

    echo "OK: no host NetworkMode in infra sources"
}

# ---- Main -------------------------------------------------------------------

main() {
    local dockerfile

    shopt -s nullglob
    local -a dockerfiles=("${REPO_ROOT}/infra/docker"/Dockerfile*)
    if ((${#dockerfiles[@]} == 0)); then
        fail "no Dockerfiles found under infra/docker/"
    fi

    for dockerfile in "${dockerfiles[@]}"; do
        assert_dockerfile_non_root "${dockerfile}"
    done

    assert_no_privileged_true
    assert_no_host_network_mode
}

main "$@"
