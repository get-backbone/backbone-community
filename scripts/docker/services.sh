#!/usr/bin/env bash
set -euo pipefail

# services.sh
# Type: executable
# Start or stop docker compose services.
# Usage: ./services.sh start|stop <service>

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli docker
}

usage() {
    cat << EOF
Usage: $(basename "$0") start|stop <service>

Examples:
    $(basename "$0") start floci
    $(basename "$0") stop postgres
EOF
}

# ---- Main -------------------------------------------------------------------

main() {
    local action="${1:-}"
    local service="${2:-}"
    local container_id

    validate_dependencies

    if [[ -z "$service" ]]; then
        usage
        exit 1
    fi

    case "$action" in
        start)
            container_id=$(docker compose ps -q "$service")
            if [ -n "$container_id" ]; then
                echo "🚀 Starting existing container for $service..."
                docker compose start "$service"
            else
                echo "🚀 No existing container found for $service, creating and starting..."
                docker compose up -d "$service"
            fi
            echo "✅ $service started."
            ;;
        stop)
            container_id=$(docker compose ps -q "$service")
            if [ -n "$container_id" ]; then
                echo "🛑 Stopping container for $service..."
                docker compose stop "$service"
                echo "✅ $service stopped."
            else
                echo "No running container found for $service."
            fi
            ;;
        *)
            echo "Unknown command: ${action:-<none>}"
            usage
            exit 1
            ;;
    esac
}

main "$@"
