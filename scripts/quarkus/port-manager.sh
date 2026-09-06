#!/usr/bin/env bash
set -euo pipefail

# port-manager.sh
# Type: executable
# Check or kill processes listening on ports defined in config/quarkus-ports.env.
# Usage: ./port-manager.sh status|kill

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli gum
    require_cli lsof
}

show_usage_panel() {
    gum_panel "${GUM_PANEL_WIDTH}" \
        "Port Manager" \
        "" \
        "Usage: $(basename "$0") status|kill" \
        "" \
        "  status  - Show which ports are in use" \
        "  kill    - Kill processes listening on configured ports"
}

load_ports_from_env() {
    local ports_env="$1"
    local -n ports_out=$2
    local -n names_out=$3
    local line name port display_name

    if [[ ! -f "$ports_env" ]]; then
        log_error "Ports file not found: $ports_env"
        exit 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        if [[ "$line" =~ ^[[:space:]]*([A-Z_]+)=([0-9]+)[[:space:]]*$ ]]; then
            name="${BASH_REMATCH[1]}"
            port="${BASH_REMATCH[2]}"
            display_name="${name%_PORT}"
            ports_out+=("$port")
            names_out+=("$display_name")
        fi
    done < "$ports_env"

    if [[ ${#ports_out[@]} -eq 0 ]]; then
        log_warn "No ports found in $ports_env"
        exit 0
    fi
}

check_port() {
    local port="$1"
    lsof -ti ":$port" 2> /dev/null || true
}

get_process_info() {
    local port="$1"
    local pid cmd user

    pid=$(lsof -ti ":$port" 2> /dev/null | head -n1)
    if [[ -z "$pid" ]]; then
        echo ""
        return
    fi

    cmd=$(ps -p "$pid" -o comm= 2> /dev/null || echo "unknown")
    user=$(ps -p "$pid" -o user= 2> /dev/null || echo "unknown")
    echo "$pid|$cmd|$user"
}

kill_port() {
    local port="$1"
    local pids

    pids=$(lsof -ti ":$port" 2> /dev/null || true)
    if [[ -z "$pids" ]]; then
        return 1
    fi

    echo "$pids" | while read -r pid; do
        kill "$pid" 2> /dev/null || true
    done
    return 0
}

format_in_use_row() {
    local port="$1"
    local name="$2"
    local info="$3"
    local pid cmd user

    IFS='|' read -r pid cmd user <<< "$info"
    printf '%s | %s | %s | %s | %s' \
        "$(gum_error ":$port")" \
        "$(gum_accent "$name")" \
        "$(gum_warn "$pid")" \
        "$(gum_muted "$cmd")" \
        "$(gum_muted "$user")"
}

show_port_status() {
    local -n ports_ref=$1
    local -n port_names_ref=$2
    local i port name info found_in_use=false
    local -a lines=()
    local -a in_use_ports=() in_use_names=() in_use_info=()

    for i in "${!ports_ref[@]}"; do
        port="${ports_ref[$i]}"
        name="${port_names_ref[$i]}"
        info=$(get_process_info "$port")

        if [[ -n "$info" ]]; then
            found_in_use=true
            in_use_ports+=("$port")
            in_use_names+=("$name")
            in_use_info+=("$info")
        fi
    done

    lines+=("Port Status" "")

    if [[ "$found_in_use" == false ]]; then
        lines+=("$(gum_success "✓ All ports are free")")
        gum_panel "${GUM_PANEL_WIDTH}" "${lines[@]}"
        return 0
    fi

    lines+=("$(gum_header "Port | Service Name | PID | Process | User")" "")

    for i in "${!in_use_ports[@]}"; do
        lines+=("$(format_in_use_row "${in_use_ports[$i]}" "${in_use_names[$i]}" "${in_use_info[$i]}")")
    done

    gum_panel "${GUM_PANEL_WIDTH}" "${lines[@]}"
}

kill_configured_ports() {
    local -n ports_ref=$1
    local -n port_names_ref=$2
    local i port name pids info pid cmd user killed_any=false
    local -a lines=("Killing Processes on Ports" "")

    for i in "${!ports_ref[@]}"; do
        port="${ports_ref[$i]}"
        name="${port_names_ref[$i]}"
        pids=$(check_port "$port")

        if [[ -n "$pids" ]]; then
            killed_any=true
            info=$(get_process_info "$port")
            IFS='|' read -r pid cmd user <<< "$info"

            lines+=("$(gum_error "Killing process on port :$port ($name)") - $(gum_muted "PID: $pid, Process: $cmd, User: $user")")

            if kill_port "$port"; then
                lines+=("$(gum_success "  ✓ Killed")")
            else
                lines+=("$(gum_error "  ✗ Failed to kill")")
            fi
        fi
    done

    if [[ "$killed_any" == false ]]; then
        lines+=("$(gum_success "✓ No processes found on configured ports")")
    fi

    gum_panel "${GUM_PANEL_WIDTH}" "${lines[@]}"
}

# ---- Main -------------------------------------------------------------------

main() {
    local action="${1:-}"
    local project_root ports_env
    local -a ports=() port_names=()

    validate_dependencies

    if [[ "$action" != "status" && "$action" != "kill" ]]; then
        show_usage_panel
        exit 1
    fi

    project_root=$(get_project_root)
    ports_env="${project_root}/config/quarkus-ports.env"
    load_ports_from_env "$ports_env" ports port_names

    case "$action" in
        status)
            show_port_status ports port_names
            ;;
        kill)
            kill_configured_ports ports port_names
            ;;
    esac
}

main "$@"
