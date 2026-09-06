#!/usr/bin/env bash
set -euo pipefail

# status.sh
# Type: executable
# Show status of docker containers.
# Usage: ./status.sh <service1> [service2] [service3] ...

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli gum
    require_cli jq
    require_cli docker
}

get_container_id() {
    local svc="$1"
    docker ps -a --filter "name=^/${svc}$" -q
}

get_ports() {
    local cid="$1"
    local ports
    ports=$(docker inspect "$cid" 2> /dev/null |
        jq -r '.[] | .NetworkSettings.Ports // {} | to_entries[]? | select(.value != null and (.value[0].HostPort != null)) | "\(.value[0].HostPort):\(.key | split("/")[0])"' |
        paste -sd ", " -)
    [[ -z "$ports" ]] && ports="-"
    echo "$ports"
}

style_container_state() {
    local state="$1"
    case "$state" in
        running) gum_success "$state" ;;
        not\ created) gum_error "$state" ;;
        *) gum_warn "$state" ;;
    esac
}

format_status_row() {
    local service="$1"
    local state="$2"
    local ports="$3"
    local styled_state service_name state_padding

    styled_state=$(style_container_state "$state")
    service_name=$(printf "%-12s" "$service")
    state_padding=$(printf "%*s" $((10 - ${#state})) "")
    printf '%s | %s%s | %s' "$service_name" "$styled_state" "$state_padding" "$ports"
}

show_usage_panel() {
    gum_panel "${GUM_PANEL_WIDTH}" \
        "Docker Status" \
        "" \
        "Usage: $(basename "$0") <service1> [service2] ..." \
        "" \
        "Examples:" \
        "  $(basename "$0") floci jaeger"
}

# ---- Main -------------------------------------------------------------------

main() {
    local services=("$@")
    local s cid state ports
    local -a lines=()

    validate_dependencies

    if [[ ${#services[@]} -eq 0 ]]; then
        show_usage_panel
        exit 1
    fi

    lines+=(
        "Docker Container Status"
        ""
        "$(gum_header "SERVICE      | STATE      | PORTS")"
        ""
    )

    for s in "${services[@]}"; do
        cid=$(get_container_id "$s")
        if [[ -n "$cid" ]]; then
            state=$(docker inspect "$cid" --format '{{.State.Status}}' 2> /dev/null || echo "unknown")
            ports=$(get_ports "$cid")
        else
            state="not created"
            ports="-"
        fi
        lines+=("$(format_status_row "$s" "$state" "$ports")")
    done

    gum_panel "${GUM_PANEL_WIDTH}" "${lines[@]}"
}

main "$@"
