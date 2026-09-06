#!/usr/bin/env bash
set -euo pipefail

# coverage-summary.sh
# Type: executable
# Extract coverage metrics from Clover XML and generate GitHub Actions job summary.
# Usage: ./coverage-summary.sh [clover-xml-path]

# ---- Functions --------------------------------------------------------------

generate_summary() {
    local percentage="$1"
    local covered="$2"
    local total="$3"
    local github_step_summary="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

    cat >> "$github_step_summary" << EOF
## 📊 Code Coverage Report

| Metric | Value |
|--------|-------|
| **Coverage** | ${percentage}% |
| **Lines Covered** | ${covered} / ${total} |

📄 **Download the full HTML report from the artifact below**

> Report generated at: $(date -u +'%Y-%m-%d %H:%M:%S UTC')
EOF
}

# ---- Main -------------------------------------------------------------------

main() {
    local clover_xml="${1:-target/site/clover/clover.xml}"
    local github_output="${GITHUB_OUTPUT:-/dev/stdout}"
    local covered=0 total=0 percentage="0"

    echo "🔍 Checking for Clover XML at: $clover_xml" >&2
    if [ -f "$clover_xml" ]; then
        echo "✅ Clover XML file found" >&2
        echo "📏 File size: $(wc -c < "$clover_xml") bytes" >&2

        if ! command -v xmllint &> /dev/null; then
            echo "❌ xmllint not found - installing libxml2-utils" >&2
            sudo apt-get update -qq && sudo apt-get install -y libxml2-utils >&2
        fi

        covered=$(xmllint --xpath "string(/coverage/project/metrics/@coveredstatements)" "$clover_xml" 2> /dev/null || echo "0")
        total=$(xmllint --xpath "string(/coverage/project/metrics/@statements)" "$clover_xml" 2> /dev/null || echo "0")

        echo "📊 Extracted values - covered: $covered, total: $total" >&2

        if [ "$total" -gt 0 ] 2> /dev/null; then
            percentage=$(awk "BEGIN {printf \"%.2f\", ($covered / $total) * 100}")
        else
            percentage="0"
            echo "⚠️  Warning: Total statements is 0 or invalid" >&2
            echo "🔍 First 20 lines of XML file:" >&2
            head -20 "$clover_xml" >&2
        fi
    else
        echo "❌ Clover XML file not found at: $clover_xml" >&2
        echo "🔍 Checking for clover files in target/site/clover/:" >&2
        ls -la target/site/clover/ 2>&1 || echo "Directory does not exist" >&2
        echo "🔍 Checking for clover files in target/:" >&2
        find target -name "clover.xml" -type f 2>&1 | head -10 || true
    fi

    {
        echo "percentage=$percentage"
        echo "covered=$covered"
        echo "total=$total"
    } >> "$github_output"

    generate_summary "$percentage" "$covered" "$total"
}

main "$@"
