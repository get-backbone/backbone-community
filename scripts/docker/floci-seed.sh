#!/usr/bin/env bash
set -euo pipefail

# floci-seed.sh
# Type: executable
# Seed notification templates into DynamoDB on Floci (or any endpoint awslocal targets).
# Usage: ./floci-seed.sh

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# ---- Constants --------------------------------------------------------------

readonly TABLE_NAME="NOTIFICATION-TEMPLATES"
readonly TEMPLATES_DIR="${SCRIPT_DIR}"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli awslocal
    require_cli jq
    require_cli envsubst
}

seed_template_from_file() {
    local template_file=$1
    local template_path="${TEMPLATES_DIR}/${template_file}"
    local processed_template dynamodb_item template_id

    if [[ ! -f "$template_path" ]]; then
        log_error "Template file not found: $template_path"
        return 1
    fi

    export CREATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    processed_template=$(envsubst < "$template_path")

    dynamodb_item=$(echo "$processed_template" | jq -c '
    {
      templateId: {S: .templateId},
      version: {N: (.version | tostring)},
      channel: {S: .channel},
      content: {
        M: {
          subject: {S: .content.subject},
          htmlBody: {S: .content.htmlBody},
          textBody: {S: .content.textBody},
          placeholders: {
            L: [.content.placeholders[] | {S: .}]
          }
        }
      }
    } +
    (if .metadata then {
      metadata: {
        M: (.metadata | to_entries | map({key: .key, value: {S: (.value | tostring)}}) | from_entries)
      }
    } else {} end) +
    (if .s3Reference then {s3Reference: {S: .s3Reference}} else {} end) +
    (if .createdAt then {createdAt: {S: (.createdAt | tostring)}} else {} end) +
    (if .updatedAt then {updatedAt: {S: (.updatedAt | tostring)}} else {} end)
  ')

    awslocal dynamodb put-item \
        --table-name "$TABLE_NAME" \
        --item "$dynamodb_item" > /dev/null 2>&1

    template_id=$(echo "$processed_template" | jq -r '.templateId')
    echo "✅ Seeded template: $template_id"
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_dependencies

    echo "🌱 Seeding notification templates..."

    seed_template_from_file "email-welcome-v1.template.json"
    seed_template_from_file "email-password-reset-v1.template.json"

    echo "🌿 Notification templates seed complete."
}

main "$@"
