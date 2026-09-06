#!/usr/bin/env bash
set -euo pipefail

# test-token-validation-cache.sh
# Type: executable
# Test token validation caching by making multiple requests with the same token.
# Usage: ./test-token-validation-cache.sh [ACTOR_ID] [ITERATIONS]

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

# ---- Constants --------------------------------------------------------------

readonly AUTH_SERVICE_PORT="${AUTH_SERVICE_PORT:-8100}"
readonly ACTOR_BFF_PORT="${ACTOR_BFF_PORT:-8500}"
readonly ACTOR_SERVICE_PORT="${ACTOR_SERVICE_PORT:-8101}"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli curl
    require_cli jq
    require_cli python3
    require_cli gum
}

extract_actor_id_from_token() {
    local token="$1"
    local payload
    payload=$(echo "$token" | cut -d'.' -f2)

    python3 -c "
import sys
import base64
import json

try:
    payload = sys.argv[1]
    padding = 4 - len(payload) % 4
    if padding != 4:
        payload += '=' * padding

    payload = payload.replace('-', '+').replace('_', '/')
    decoded = base64.b64decode(payload)
    data = json.loads(decoded)
    print(data.get('sub', ''))
except Exception:
    print('')
" "$payload" 2> /dev/null || echo ""
}

get_access_token() {
    local response token
    response=$(curl -s -X POST "http://localhost:${AUTH_SERVICE_PORT}/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"username": "bob@example.com", "password": "Rogue_One1"}')

    token=$(echo "$response" | jq -r '.accessToken // empty')

    if [ -z "$token" ] || [ "$token" = "null" ]; then
        log_error "Failed to get access token. Response: $response"
        exit 1
    fi

    echo "$token"
}

make_timed_request() {
    local url="$1"
    local token="$2"
    local request_num="$3"
    local start_time end_time response http_code body duration

    start_time=$(date +%s%N)
    response=$(curl -s -w "\n%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $token" 2>&1)
    end_time=$(date +%s%N)

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    duration=$(((end_time - start_time) / 1000000))

    if [ "$http_code" != "200" ]; then
        log_error "Request $request_num failed with HTTP $http_code"
        echo "$body" | jq . 2> /dev/null || echo "$body"
        return 1
    fi

    echo "$duration"
    return 0
}

# ---- Main -------------------------------------------------------------------

main() {
    local actor_id="${1:-}"
    local iterations="${2:-5}"
    local target_port="${TARGET_PORT:-$ACTOR_BFF_PORT}"
    local target_url="http://localhost:${target_port}"
    local access_token endpoint total_time=0 first_request_time=0
    local i duration avg_time subsequent_avg speedup cache_metrics
    local hits_raw misses_raw hits misses total_requests hit_rate

    validate_dependencies
    export AWS_PAGER=""

    echo ""
    gum style --foreground 11 --bold "⚠️  Prerequisite Check"
    echo ""
    gum style --foreground 240 "This script requires Cognito users to be seeded to Postgres."
    gum style --foreground 240 "If you haven't run the seed script, this test will fail."
    echo ""
    gum style --foreground 14 "To seed the database, run:"
    gum style --foreground 212 --bold "  task seed:it:up                        # integration fixtures"
    echo ""

    log_info "🔐 Token Validation Cache Test"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Target: $target_url"
    log_info "Iterations: $iterations"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    log_info ""
    log_info "Step 1: Getting access token..."
    access_token=$(get_access_token)
    log_info "✅ Access token obtained"

    if [ -z "$actor_id" ]; then
        log_info ""
        log_info "Step 2: Extracting actor ID from token..."
        actor_id=$(extract_actor_id_from_token "$access_token")

        if [ -z "$actor_id" ]; then
            log_error "Failed to extract actor ID from token"
            log_info "Please provide actor ID as first argument:"
            log_info "  ./test-token-validation-cache.sh <actor-id> [iterations]"
            exit 1
        fi
        log_info "✅ Candidate ID: $actor_id"
    else
        log_info ""
        log_info "Step 2: Using provided actor ID: $actor_id"
    fi

    log_info ""
    log_info "Step 3: Making $iterations requests..."
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    endpoint="${target_url}/actors/${actor_id}"

    for i in $(seq 1 "$iterations"); do
        if ! duration=$(make_timed_request "$endpoint" "$access_token" "$i"); then
            exit 1
        fi

        total_time=$((total_time + duration))

        if [ "$i" -eq 1 ]; then
            first_request_time=$duration
            log_info "  Request $i: ${duration}ms (cache miss - first request)"
        else
            log_info "  Request $i: ${duration}ms (cache hit)"
        fi
    done

    log_info ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "📊 Results"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    avg_time=$((total_time / iterations))
    if [ "$iterations" -gt 1 ]; then
        subsequent_avg=$(((total_time - first_request_time) / (iterations - 1)))
        speedup=$(awk "BEGIN {printf \"%.1f\", $first_request_time / $subsequent_avg}")

        log_info "First request (cache miss):  ${first_request_time}ms"
        log_info "Subsequent avg (cache hit): ${subsequent_avg}ms"
        log_info "Speedup:                     ${speedup}x faster"
    else
        log_info "First request (cache miss):  ${first_request_time}ms"
        log_info "Average:                     ${avg_time}ms"
    fi

    log_info "Total time:                  ${total_time}ms"
    log_info "Average time:                ${avg_time}ms"

    log_info ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "📈 Cache Metrics"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    log_info "Checking cache metrics at: ${target_url}/q/metrics"
    cache_metrics=$(curl -s "${target_url}/q/metrics" | grep -E "cache.*token-validation" || true)

    if [ -n "$cache_metrics" ]; then
        echo "$cache_metrics" | while IFS= read -r line; do
            log_info "  $line"
        done

        hits_raw=$(echo "$cache_metrics" | grep 'result="hit"' | grep -oE '[0-9]+\.?[0-9]*' | head -1 || echo "0")
        misses_raw=$(echo "$cache_metrics" | grep 'result="miss"' | grep -oE '[0-9]+\.?[0-9]*' | head -1 || echo "0")
        hits=$(echo "$hits_raw" | cut -d'.' -f1)
        misses=$(echo "$misses_raw" | cut -d'.' -f1)

        if [ -n "$hits" ] && [ -n "$misses" ] && [ "$hits" != "0" ] && [ "$misses" != "0" ]; then
            total_requests=$(awk "BEGIN {printf \"%.0f\", $hits + $misses}")
            hit_rate=$(awk "BEGIN {printf \"%.1f\", ($hits / ($hits + $misses)) * 100}")
            log_info ""
            log_info "Cache hit rate: ${hit_rate}% (${hits} hits / ${total_requests} total)"
        fi
    else
        log_warn "No cache metrics found. Ensure cache metrics are enabled."
    fi

    log_info ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "✅ Cache test completed!"
    log_info ""
    log_info "Expected behavior:"
    log_info "  - First request should be slower (cache miss)"
    log_info "  - Subsequent requests should be faster (cache hit)"
    log_info "  - Cache hit rate should increase with more requests"
}

main "$@"
