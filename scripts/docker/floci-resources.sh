#!/usr/bin/env bash
set -euo pipefail

# floci-resources.sh
# Type: executable
# Create Floci AWS resources (DynamoDB tables, S3 buckets, Cognito pools).

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=scripts/docker/floci-cognito-resources.sh
source "${SCRIPT_DIR}/floci-cognito-resources.sh"

# Floci keys Secrets Manager / SSM by region. Set AWS_REGION so awslocal
# (defaults to us-east-1 without ~/.aws) matches the AWS SDK region chain used by Quarkus.
export AWS_REGION="${AWS_REGION:-us-west-2}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-${AWS_REGION}}"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli docker
    require_cli awslocal
}

ensure_floci_running() {
    if ! docker ps --format '{{.Image}}' | grep -qi 'floci'; then
        log_error "Floci container not running. Start it with: task docker:start -- floci"
        exit 1
    fi
}

create_dynamodb_tables() {
    awslocal dynamodb create-table \
        --table-name 'DOCUMENTS' \
        --attribute-definitions \
        AttributeName=transactionId,AttributeType=S \
        AttributeName=actorId,AttributeType=S \
        AttributeName=formattedName,AttributeType=S \
        AttributeName=parseTimestamp,AttributeType=S \
        --key-schema \
        AttributeName=transactionId,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
        --global-secondary-indexes '[
      {
        "IndexName": "ActorIdIndex",
        "KeySchema": [
          {"AttributeName": "actorId", "KeyType": "HASH"},
          {"AttributeName": "parseTimestamp", "KeyType": "RANGE"}
        ],
        "Projection": {"ProjectionType": "ALL"},
        "ProvisionedThroughput": {"ReadCapacityUnits":1,"WriteCapacityUnits":1}
      },
      {
        "IndexName": "NameIndex",
        "KeySchema": [{"AttributeName": "formattedName", "KeyType": "HASH"}],
        "Projection": {"ProjectionType": "ALL"},
        "ProvisionedThroughput": {"ReadCapacityUnits":1,"WriteCapacityUnits":1}
      }
  ]' > /dev/null 2>&1 || echo "⚠️ DynamoDB table 'DOCUMENTS' may already exist."

    echo "✅ DynamoDB table: 'DOCUMENTS' ready."

    awslocal dynamodb create-table \
        --table-name 'NOTIFICATION-TEMPLATES' \
        --attribute-definitions \
        AttributeName=templateId,AttributeType=S \
        AttributeName=version,AttributeType=N \
        AttributeName=channel,AttributeType=S \
        --key-schema \
        AttributeName=templateId,KeyType=HASH \
        AttributeName=version,KeyType=RANGE \
        --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
        --global-secondary-indexes '[
      {
        "IndexName": "channel-index",
        "KeySchema": [
          {"AttributeName": "channel", "KeyType": "HASH"},
          {"AttributeName": "templateId", "KeyType": "RANGE"}
        ],
        "Projection": {"ProjectionType": "ALL"},
        "ProvisionedThroughput": {"ReadCapacityUnits":1,"WriteCapacityUnits":1}
      }
  ]' > /dev/null 2>&1 || echo "⚠️ DynamoDB table 'NOTIFICATION-TEMPLATES' may already exist."

    echo "✅ DynamoDB table: 'NOTIFICATION-TEMPLATES' ready."
}

create_s3_buckets() {
    awslocal s3 mb 's3://backbone-documents' > /dev/null 2>&1 || true
    awslocal s3api put-bucket-versioning \
        --bucket backbone-documents \
        --versioning-configuration Status=Enabled

    echo "✅ S3 bucket: 'backbone-documents' ready."
}

create_audit_events_queues() {
    awslocal sqs create-queue \
        --queue-name 'backbone-audit-events-dlq' > /dev/null 2>&1 ||
        echo "⚠️ SQS queue 'backbone-audit-events-dlq' may already exist."

    local dlq_url
    dlq_url="$(awslocal sqs get-queue-url --queue-name 'backbone-audit-events-dlq' --query 'QueueUrl' --output text)"
    local dlq_arn
    dlq_arn="$(awslocal sqs get-queue-attributes --queue-url "${dlq_url}" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)"

    awslocal sqs create-queue \
        --queue-name 'backbone-audit-events' \
        --attributes "{
            \"VisibilityTimeout\": \"60\",
            \"MessageRetentionPeriod\": \"1209600\",
            \"RedrivePolicy\": \"{\\\"deadLetterTargetArn\\\":\\\"${dlq_arn}\\\",\\\"maxReceiveCount\\\":\\\"5\\\"}\"
        }" > /dev/null 2>&1 ||
        echo "⚠️ SQS queue 'backbone-audit-events' may already exist."

    echo "✅ SQS queues: 'backbone-audit-events' (+ DLQ) ready."
}

create_audit_events_bus() {
    awslocal events create-event-bus \
        --name 'audit-events-bus' > /dev/null 2>&1 ||
        echo "⚠️ EventBridge bus 'audit-events-bus' may already exist."

    local queue_url
    queue_url="$(awslocal sqs get-queue-url --queue-name 'backbone-audit-events' --query 'QueueUrl' --output text)"
    local queue_arn
    queue_arn="$(awslocal sqs get-queue-attributes --queue-url "${queue_url}" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)"

    awslocal events put-rule \
        --name 'audit-ingest' \
        --event-bus-name 'audit-events-bus' \
        --event-pattern '{"source":["backbone.audit"],"detail-type":["AuditEvent"]}' \
        --state ENABLED > /dev/null 2>&1 ||
        echo "⚠️ EventBridge rule 'audit-ingest' may already exist."

    # InputPath $.detail keeps SQS body as AuditEventRequest JSON (matches CDK RuleTargetInput).
    awslocal events put-targets \
        --rule 'audit-ingest' \
        --event-bus-name 'audit-events-bus' \
        --targets "Id=AuditEventsQueue,Arn=${queue_arn},InputPath=\$.detail" > /dev/null 2>&1 ||
        echo "⚠️ EventBridge target for 'audit-ingest' may already exist."

    echo "✅ EventBridge: 'audit-events-bus' → 'backbone-audit-events' ready."
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_dependencies
    ensure_floci_running
    echo "🌱 Creating Floci AWS resources..."
    sleep 3

    create_dynamodb_tables
    create_s3_buckets
    create_audit_events_queues
    create_audit_events_bus
    create_cognito_resources

    echo "🌿 Floci resources created."
}

main "$@"
