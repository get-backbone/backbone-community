#!/usr/bin/env bash
# it-test-accounts.sh
# Type: module (source only — do not execute directly)
# Cognito IT fixture service account (service-test / Test-p@ssword-123) on Floci via awslocal.
# Values must stay in sync with cognito.test.* in:
#   services/auth-service/src/test/resources/application.properties

# ---- Functions --------------------------------------------------------------

# Idempotent: creates the user if missing, then always sets the permanent password.
create_test_service_account() {
    local pool_id=$1
    local service_name="test"
    local service_username="service-test"
    local fixed_password="Test-p@ssword-123"

    echo "🔐 Creating Cognito test service account (${service_username})..."

    if ! awslocal cognito-idp admin-get-user --user-pool-id "$pool_id" --username "$service_username" > /dev/null 2>&1; then
        awslocal cognito-idp admin-create-user \
            --user-pool-id "$pool_id" \
            --username "$service_username" \
            --user-attributes \
            Name=email,Value="${service_username}@backbone.internal" \
            Name=email_verified,Value=true \
            Name=custom:service_id,Value="${service_name}" \
            --temporary-password "$fixed_password" \
            --message-action SUPPRESS > /dev/null
    else
        echo "ℹ️ Service account ${service_username} already exists"
    fi

    awslocal cognito-idp admin-set-user-password \
        --user-pool-id "$pool_id" \
        --username "$service_username" \
        --password "$fixed_password" \
        --permanent > /dev/null

    echo "✅ Test service account ready (password matches auth-service/src/test/application.properties)"
    echo
}
