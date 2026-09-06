#!/usr/bin/env bash
# floci-cognito-resources.sh
# Type: module (source only — do not execute directly)
# Create Floci Cognito actor/service pools, app clients, SSM parameters, and Secrets Manager secrets.
# Idempotent when Floci override ids are stable across restarts (persistent storage).
# Uses awslocal (same :4566 endpoint as DynamoDB/S3 provisioning).

# ---- Constants --------------------------------------------------------------

readonly COGNITO_REGION="${AWS_REGION:-us-west-2}"

readonly COGNITO_ACTOR_POOL_NAME="backbone-actor-pool"
readonly COGNITO_ACTOR_CLIENT_NAME="backbone-actor-client"
readonly COGNITO_ACTOR_POOL_OVERRIDE_ID="${COGNITO_REGION}_backboneActor"
readonly COGNITO_ACTOR_CLIENT_SECRET_NAME="backbone/cognito/actor-client-secret"
readonly COGNITO_ACTOR_CLIENT_SECRET_VALUE="local-actor-client-secret"

readonly COGNITO_SERVICE_POOL_NAME="backbone-service-pool"
readonly COGNITO_SERVICE_CLIENT_NAME="backbone-service-client"
readonly COGNITO_SERVICE_POOL_OVERRIDE_ID="${COGNITO_REGION}_backboneService"
readonly COGNITO_SERVICE_CLIENT_SECRET_NAME="backbone/cognito/service-client-secret"
readonly COGNITO_SERVICE_CLIENT_SECRET_VALUE="local-service-client-secret"

readonly COGNITO_SERVICE_ACCOUNT_SECRET_PREFIX="backbone/cognito/service-account"
# Meets service-pool password policy (12+, upper, lower, number, symbol). Fixed for local Floci.
readonly COGNITO_SERVICE_ACCOUNT_PASSWORD="Local-Svc-Acct-Pass1!"
# Keep in sync with cognitoServiceAccount:true in infra/src/lib/constant/backbone-services.json
readonly COGNITO_SERVICE_ACCOUNT_NAMES=(
    actor-bff
    actor-service
    audit-service
    auth-service
    document-service
    notification-service
)

# ---- Functions --------------------------------------------------------------

put_ssm_parameter() {
    local name=$1
    local value=$2

    awslocal ssm put-parameter \
        --name "${name}" \
        --value "${value}" \
        --type String \
        --overwrite > /dev/null
}

put_secret() {
    local name=$1
    local value=$2

    if awslocal secretsmanager describe-secret --secret-id "${name}" > /dev/null 2>&1; then
        awslocal secretsmanager put-secret-value \
            --secret-id "${name}" \
            --secret-string "${value}" > /dev/null
    else
        awslocal secretsmanager create-secret \
            --name "${name}" \
            --secret-string "${value}" > /dev/null
    fi
}

find_pool_id_by_name() {
    local pool_name=$1

    awslocal cognito-idp list-user-pools --max-results 60 \
        --query "UserPools[?Name=='${pool_name}'].Id | [0]" \
        --output text
}

create_actor_pool() {
    local existing_pool_id client_id

    existing_pool_id="$(find_pool_id_by_name "${COGNITO_ACTOR_POOL_NAME}")"
    if [[ -n "${existing_pool_id}" && "${existing_pool_id}" != "None" ]]; then
        echo "ℹ️ Actor pool already exists: ${existing_pool_id}"
        put_ssm_parameter "COGNITO_ACTOR_POOL_ID" "${existing_pool_id}"
        client_id="$(awslocal cognito-idp list-user-pool-clients \
            --user-pool-id "${existing_pool_id}" \
            --query "UserPoolClients[0].ClientId" \
            --output text)"
        put_ssm_parameter "COGNITO_ACTOR_CLIENT_ID" "${client_id}"
        put_secret "${COGNITO_ACTOR_CLIENT_SECRET_NAME}" "${COGNITO_ACTOR_CLIENT_SECRET_VALUE}"
        echo "✅ Actor pool SSM/Secrets refreshed."
        return 0
    fi

    existing_pool_id="$(awslocal cognito-idp create-user-pool \
        --pool-name "${COGNITO_ACTOR_POOL_NAME}" \
        --username-attributes email \
        --auto-verified-attributes email \
        --policies 'PasswordPolicy={MinimumLength=8,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=false}' \
        --user-pool-tags "floci:override-id=${COGNITO_ACTOR_POOL_OVERRIDE_ID},floci:override-cognito-client-secret=${COGNITO_ACTOR_CLIENT_SECRET_VALUE}" \
        --query 'UserPool.Id' \
        --output text)"

    client_id="$(awslocal cognito-idp create-user-pool-client \
        --user-pool-id "${existing_pool_id}" \
        --client-name "${COGNITO_ACTOR_CLIENT_NAME}" \
        --generate-secret \
        --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_USER_SRP_AUTH ALLOW_REFRESH_TOKEN_AUTH \
        --query 'UserPoolClient.ClientId' \
        --output text)"

    put_ssm_parameter "COGNITO_ACTOR_POOL_ID" "${existing_pool_id}"
    put_ssm_parameter "COGNITO_ACTOR_CLIENT_ID" "${client_id}"
    put_secret "${COGNITO_ACTOR_CLIENT_SECRET_NAME}" "${COGNITO_ACTOR_CLIENT_SECRET_VALUE}"

    echo "✅ Actor pool ready: ${existing_pool_id} (client ${client_id})"
}

create_service_pool() {
    local existing_pool_id client_id

    existing_pool_id="$(find_pool_id_by_name "${COGNITO_SERVICE_POOL_NAME}")"
    if [[ -n "${existing_pool_id}" && "${existing_pool_id}" != "None" ]]; then
        echo "ℹ️ Service pool already exists: ${existing_pool_id}"
        put_ssm_parameter "COGNITO_SERVICE_POOL_ID" "${existing_pool_id}"
        client_id="$(awslocal cognito-idp list-user-pool-clients \
            --user-pool-id "${existing_pool_id}" \
            --query "UserPoolClients[0].ClientId" \
            --output text)"
        put_ssm_parameter "COGNITO_SERVICE_CLIENT_ID" "${client_id}"
        put_secret "${COGNITO_SERVICE_CLIENT_SECRET_NAME}" "${COGNITO_SERVICE_CLIENT_SECRET_VALUE}"
        echo "✅ Service pool SSM/Secrets refreshed."
        return 0
    fi

    existing_pool_id="$(awslocal cognito-idp create-user-pool \
        --pool-name "${COGNITO_SERVICE_POOL_NAME}" \
        --policies 'PasswordPolicy={MinimumLength=12,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=true}' \
        --schema 'Name=service_id,AttributeDataType=String,Mutable=true,Required=false,StringAttributeConstraints={MinLength=1,MaxLength=100}' \
        --user-pool-tags "floci:override-id=${COGNITO_SERVICE_POOL_OVERRIDE_ID},floci:override-cognito-client-secret=${COGNITO_SERVICE_CLIENT_SECRET_VALUE}" \
        --query 'UserPool.Id' \
        --output text)"

    client_id="$(awslocal cognito-idp create-user-pool-client \
        --user-pool-id "${existing_pool_id}" \
        --client-name "${COGNITO_SERVICE_CLIENT_NAME}" \
        --generate-secret \
        --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_USER_SRP_AUTH ALLOW_ADMIN_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
        --query 'UserPoolClient.ClientId' \
        --output text)"

    put_ssm_parameter "COGNITO_SERVICE_POOL_ID" "${existing_pool_id}"
    put_ssm_parameter "COGNITO_SERVICE_CLIENT_ID" "${client_id}"
    put_secret "${COGNITO_SERVICE_CLIENT_SECRET_NAME}" "${COGNITO_SERVICE_CLIENT_SECRET_VALUE}"

    echo "✅ Service pool ready: ${existing_pool_id} (client ${client_id})"
}

service_account_secret_json() {
    local service_name=$1
    local username="service-${service_name}"

    printf '{"username":"%s","password":"%s"}' "${username}" "${COGNITO_SERVICE_ACCOUNT_PASSWORD}"
}

ensure_service_pool_user() {
    local pool_id=$1
    local service_name=$2
    local username="service-${service_name}"
    local password=$3

    if ! awslocal cognito-idp admin-get-user --user-pool-id "${pool_id}" --username "${username}" > /dev/null 2>&1; then
        awslocal cognito-idp admin-create-user \
            --user-pool-id "${pool_id}" \
            --username "${username}" \
            --user-attributes \
            Name=email,Value="${username}@backbone.internal" \
            Name=email_verified,Value=true \
            Name=custom:service_id,Value="${service_name}" \
            --temporary-password "${password}" \
            --message-action SUPPRESS > /dev/null
    fi

    awslocal cognito-idp admin-set-user-password \
        --user-pool-id "${pool_id}" \
        --username "${username}" \
        --password "${password}" \
        --permanent > /dev/null
}

create_service_accounts() {
    local service_pool_id service_name secret_name

    service_pool_id="$(awslocal ssm get-parameter \
        --name COGNITO_SERVICE_POOL_ID \
        --query Parameter.Value \
        --output text)"

    echo "🌱 Creating Floci Cognito service accounts."
    for service_name in "${COGNITO_SERVICE_ACCOUNT_NAMES[@]}"; do
        secret_name="${COGNITO_SERVICE_ACCOUNT_SECRET_PREFIX}/${service_name}"
        put_secret "${secret_name}" "$(service_account_secret_json "${service_name}")"
        ensure_service_pool_user \
            "${service_pool_id}" \
            "${service_name}" \
            "${COGNITO_SERVICE_ACCOUNT_PASSWORD}"
        echo "  ✅ ${service_name} → ${secret_name}"
    done
}

create_cognito_resources() {
    require_cli awslocal

    echo "🌱 Creating Floci Cognito resources."
    create_actor_pool
    create_service_pool
    create_service_accounts
}
