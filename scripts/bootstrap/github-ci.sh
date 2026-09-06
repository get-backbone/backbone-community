#!/usr/bin/env bash
set -euo pipefail

# github-ci.sh
# Type: executable
# Prompts for CI-only GitHub Actions vars/secrets (not in .envrc.local).
# Usage: task bootstrap:github-ci

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/bootstrap/helpers.sh
source "${SCRIPT_DIR}/helpers.sh"
# shellcheck source=scripts/bootstrap/github-helpers.sh
source "${SCRIPT_DIR}/github-helpers.sh"

# ---- Constants --------------------------------------------------------------

readonly AWS_SANDBOX_PROFILE="backbone-sandbox"
readonly ECS_RUNTIME_MODE="native"
readonly CI_PANEL_WIDTH=80

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli gum
    require_cli gh
    require_cli yq
    require_cli aws
    require_cli gpg
}

gum_prompt_password_non_empty() {
    local prompt="$1"
    local out=""
    while true; do
        out="$(gum input --prompt "${prompt}" --password)"
        if [[ -n "${out}" ]]; then
            printf '%s\n' "${out}"
            return 0
        fi
        log_error "Value cannot be empty — please enter a non-empty value."
    done
}

confirm_operator_ready() {
    local secret_repo="$1"
    gum_panel "${CI_PANEL_WIDTH}" \
        "Publish CI-only values → GitHub Actions" \
        "" \
        "Repo: ${secret_repo}" \
        "" \
        "You will be asked for:" \
        "  • Codecov upload token" \
        "  • Sonatype Guide / OSS Index user and API key" \
        "  • GPG secret key ID (from gpg --list-secret-keys, not pubring.kbx) and passphrase" \
        "  • USER_BACKBONE_DEPLOY and PAT_BACKBONE_DEPLOY" \
        "  • INT / STAGE / PROD AWS account IDs" \
        "" \
        "BACKBONE_ECS_RUNTIME_MODE is set to ${ECS_RUNTIME_MODE} (see Runbook for JVM)."
    gum_panel_accent "${CI_PANEL_WIDTH}" \
        "Create Codecov, Sonatype Guide, and a signing GPG key first if needed." \
        "Codecov: https://docs.codecov.com/docs/codecov-uploader#upload-token" \
        "OSS Index: https://guide.sonatype.com/settings/tokens (PAT → API key; email as user)" \
        "GPG key id is the hex after the algo, e.g. the value after ed25519/ in --list-secret-keys"
    if ! gum confirm "Are you ready to continue and set GitHub Actions CI secrets?" --default=false; then
        log_info "Exiting without changes. Re-run task bootstrap:github-ci when you are ready."
        exit 0
    fi
}

prompt_third_party_secrets() {
    CODECOV_TOKEN="$(gum_prompt_password_non_empty "CODECOV_TOKEN: ")"
    OSS_INDEX_USER="$(gum_prompt_non_empty "OSS_INDEX_USER (Sonatype Guide email; username is ignored for a PAT): ")"
    OSS_INDEX_API_KEY="$(gum_prompt_password_non_empty "OSS_INDEX_API_KEY (Guide token from https://guide.sonatype.com/settings/tokens): ")"
}

default_gpg_secret_key_id() {
    gpg --list-secret-keys --with-colons 2> /dev/null | awk -F: '/^sec:/ { print $5; exit }'
}

encode_gpg_private_key() {
    local key_id="$1"
    local armoured
    armoured="$(gpg --armor --export-secret-keys "${key_id}")"
    if [[ -z "${armoured}" ]]; then
        log_error "gpg did not export a secret key for ${key_id}"
        echo "List keys with: gpg --list-secret-keys --keyid-format=long" >&2
        exit 1
    fi
    printf '%s' "${armoured}" | base64 | tr -d '\n'
}

prompt_gpg_secrets() {
    local key_id
    key_id="$(gum_prompt_non_empty "GPG secret key ID (gpg --list-secret-keys; not ~/.gnupg/pubring.kbx): " "$(default_gpg_secret_key_id)")"
    GPG_PRIVATE_KEY="$(encode_gpg_private_key "${key_id}")"
    GPG_PASSPHRASE="$(gum_prompt_password_non_empty "GPG_PASSPHRASE: ")"
}

prompt_github_deploy_identity() {
    local default_user
    default_user="$(gh api user --jq .login)"
    USER_BACKBONE_DEPLOY="$(gum_prompt_non_empty "USER_BACKBONE_DEPLOY: " "${default_user}")"
    PAT_BACKBONE_DEPLOY="$(gum_prompt_password_non_empty "PAT_BACKBONE_DEPLOY token (same classic PAT as task bootstrap:mvn): ")"
}

sandbox_aws_account_id() {
    aws sts get-caller-identity \
        --profile "${AWS_SANDBOX_PROFILE}" \
        --query Account \
        --output text
}

prompt_aws_account_ids() {
    local default_account
    default_account="$(sandbox_aws_account_id)"
    default_account="$(trim_whitespace "${default_account}")"
    if [[ -z "${default_account}" ]]; then
        log_error "Could not read AWS account ID from profile ${AWS_SANDBOX_PROFILE}"
        exit 1
    fi
    INT_AWS_ACCOUNT_ID="$(gum_prompt_non_empty "INT_AWS_ACCOUNT_ID: " "${default_account}")"
    STAGE_AWS_ACCOUNT_ID="$(gum_prompt_non_empty "STAGE_AWS_ACCOUNT_ID: " "${default_account}")"
    PROD_AWS_ACCOUNT_ID="$(gum_prompt_non_empty "PROD_AWS_ACCOUNT_ID: " "${default_account}")"
}

publish_ci_values() {
    local secret_repo="$1"
    publish_actions_secret CODECOV_TOKEN "${CODECOV_TOKEN}" "${secret_repo}"
    publish_actions_secret OSS_INDEX_USER "${OSS_INDEX_USER}" "${secret_repo}"
    publish_actions_secret OSS_INDEX_API_KEY "${OSS_INDEX_API_KEY}" "${secret_repo}"
    publish_actions_secret GPG_PRIVATE_KEY "${GPG_PRIVATE_KEY}" "${secret_repo}"
    publish_actions_secret GPG_PASSPHRASE "${GPG_PASSPHRASE}" "${secret_repo}"
    publish_actions_secret PAT_BACKBONE_DEPLOY "${PAT_BACKBONE_DEPLOY}" "${secret_repo}"
    publish_actions_variable USER_BACKBONE_DEPLOY "${USER_BACKBONE_DEPLOY}" "${secret_repo}"
    publish_actions_variable INT_AWS_ACCOUNT_ID "${INT_AWS_ACCOUNT_ID}" "${secret_repo}"
    publish_actions_variable STAGE_AWS_ACCOUNT_ID "${STAGE_AWS_ACCOUNT_ID}" "${secret_repo}"
    publish_actions_variable PROD_AWS_ACCOUNT_ID "${PROD_AWS_ACCOUNT_ID}" "${secret_repo}"
    publish_actions_variable BACKBONE_ECS_RUNTIME_MODE "${ECS_RUNTIME_MODE}" "${secret_repo}"
}

# ---- Main -------------------------------------------------------------------

main() {
    local secret_repo

    validate_dependencies
    require_gh_auth
    secret_repo="$(resolve_github_actions_repo)"
    confirm_operator_ready "${secret_repo}"
    prompt_third_party_secrets
    prompt_gpg_secrets
    prompt_github_deploy_identity
    prompt_aws_account_ids
    publish_ci_values "${secret_repo}"
}

main "$@"
