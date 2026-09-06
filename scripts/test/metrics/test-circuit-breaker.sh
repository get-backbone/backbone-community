#!/usr/bin/env bash
set -euo pipefail

# test-circuit-breaker.sh
# Type: executable
# Test circuit breaker state changes by triggering failures.
# Usage: ./test-circuit-breaker.sh [REQUEST_COUNT] [FAIL_COUNT]

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli curl
    require_cli jq
}

# ---- Main -------------------------------------------------------------------

main() {
    local request_count="${1:-10}"
    local fail_count="${2:-5}"
    local success_count i

    validate_dependencies
    export AWS_PAGER=""

    if [ "$fail_count" -gt "$request_count" ]; then
        log_error "FAIL_COUNT ($fail_count) cannot be greater than REQUEST_COUNT ($request_count)"
        exit 1
    fi

    log_info "🔌 Circuit Breaker Test"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Total requests: $request_count"
    log_info "Failure requests: $fail_count"
    log_info "Success requests: $((request_count - fail_count))"
    log_info "Failure rate: $(awk "BEGIN {printf \"%.1f\", ($fail_count/$request_count)*100}")%"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    log_info ""
    log_info "Making $fail_count failure requests..."
    for i in $(seq 1 "$fail_count"); do
        log_info "  ❌ Failure request $i/$fail_count"
        if ! curl -s -X POST "http://localhost:8100/test/circuit-breaker/trigger?fail=true&count=1" > /dev/null 2>&1; then
            log_info "    (Expected failure)"
        fi
        sleep 0.2
    done

    success_count=$((request_count - fail_count))
    if [ "$success_count" -gt 0 ]; then
        log_info ""
        log_info "Making $success_count success requests..."
        for i in $(seq 1 "$success_count"); do
            log_info "  ✅ Success request $i/$success_count"
            curl -s -X POST "http://localhost:8100/test/circuit-breaker/trigger?fail=false&count=1" | jq -r '.message // .' 2> /dev/null || true
            sleep 0.2
        done
    fi

    log_info ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "✅ Circuit breaker test completed!"
    log_info ""
    log_info "Check metrics at: http://localhost:8100/q/metrics"
    log_info "Look for: circuit_breaker_state_changes_total"
    log_info ""
    log_info "Example query:"
    log_info "  curl -s http://localhost:8100/q/metrics | grep circuit_breaker_state_changes"
}

main "$@"
