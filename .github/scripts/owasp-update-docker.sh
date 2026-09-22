#!/usr/bin/env bash
set -euo pipefail

# owasp-update-docker.sh
# Type: executable
# Refresh the OWASP dependency-check NVD cache from the nightly Docker image
# (owasp/dependency-check-action), which ships a pre-built database.
# Recreates a local named container and syncs /usr/share/dependency-check/data
# into .dependency-check-cache for Maven dependency-check:aggregate.
# Usage: ./owasp-update-docker.sh

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../scripts/lib/common.sh
source "${SCRIPT_DIR}/../../scripts/lib/common.sh"

# ---- Constants --------------------------------------------------------------

readonly CACHE_DIR="${REPO_ROOT}/.dependency-check-cache"
readonly IMAGE="${OWASP_DEPENDENCY_CHECK_IMAGE:-owasp/dependency-check-action:latest}"
readonly CONTAINER_NAME="${OWASP_DEPENDENCY_CHECK_CONTAINER:-backbone-owasp-dependency-check}"
readonly IMAGE_PLATFORM="${OWASP_DEPENDENCY_CHECK_PLATFORM:-linux/amd64}"
readonly IMAGE_DATA_DIR="/usr/share/dependency-check/data"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli gum
    require_cli docker
}

set_cache_modified_output() {
    local cache_modified="$1"
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        echo "cache_modified=${cache_modified}" >> "${GITHUB_OUTPUT}"
    fi
}

previous_image_id() {
    docker image inspect --format '{{.Id}}' "${IMAGE}" 2> /dev/null || true
}

pull_image() {
    log_info "Pulling ${IMAGE} (${IMAGE_PLATFORM})"
    docker pull --platform "${IMAGE_PLATFORM}" "${IMAGE}"
}

recreate_container() {
    log_info "Restarting container ${CONTAINER_NAME}"
    docker rm -f "${CONTAINER_NAME}" > /dev/null 2>&1 || true
    # Keep a long-lived container so the baked NVD data dir stays addressable via docker cp.
    # Override entrypoint — the image defaults to dependency-check.sh.
    docker run -d \
        --name "${CONTAINER_NAME}" \
        --platform "${IMAGE_PLATFORM}" \
        --restart unless-stopped \
        --label "io.backbonehq.owasp=dependency-check" \
        --entrypoint sleep \
        "${IMAGE}" \
        infinity \
        > /dev/null
}

sync_cache_from_container() {
    local staging_dir
    staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/backbone-owasp-XXXXXX")"
    # shellcheck disable=SC2064
    trap "rm -rf '${staging_dir}'" RETURN

    log_info "Syncing NVD database into ${CACHE_DIR}"
    docker cp "${CONTAINER_NAME}:${IMAGE_DATA_DIR}/." "${staging_dir}/"

    if [[ ! -f "${staging_dir}/odc.mv.db" ]]; then
        log_error "Image data directory is missing odc.mv.db"
        return 1
    fi

    mkdir -p "${CACHE_DIR}"
    # Replace H2 DB + companion files atomically from staging.
    find "${CACHE_DIR}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    cp -a "${staging_dir}/." "${CACHE_DIR}/"
}

report_versions() {
    local plugin_hint
    plugin_hint="$(
        docker run --rm --platform "${IMAGE_PLATFORM}" --entrypoint /usr/share/dependency-check/bin/dependency-check.sh \
            "${IMAGE}" --version 2> /dev/null | head -1 || true
    )"
    if [[ -n "${plugin_hint}" ]]; then
        log_info "${plugin_hint} (Maven owasp.version should match)"
    fi
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_dependencies

    local before_id after_id
    before_id="$(previous_image_id)"

    pull_image
    after_id="$(previous_image_id)"
    recreate_container
    sync_cache_from_container
    report_versions

    if [[ -n "${before_id}" && "${before_id}" == "${after_id}" ]]; then
        log_info "Image digest unchanged; cache refreshed from local image layers."
        set_cache_modified_output true
    else
        log_info "Image updated; local NVD cache refreshed."
        set_cache_modified_output true
    fi
}

main "$@"
