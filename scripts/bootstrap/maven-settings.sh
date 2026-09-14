#!/usr/bin/env bash
set -euo pipefail

# maven-settings.sh
# Type: executable
# Configure ~/.m2/settings.xml for GitHub Packages auth.
# Usage: task bootstrap:mvn

# ---- Imports ----------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

# ---- Functions --------------------------------------------------------------

validate_dependencies() {
    require_cli gum
}

# ---- Main -------------------------------------------------------------------

main() {
    local settings_dir settings_file github_username github_token backup_file

    validate_dependencies

    settings_dir="${HOME}/.m2"
    settings_file="${settings_dir}/settings.xml"

    gum_panel 70 "Configure Maven settings.xml for GitHub Packages"

    github_username="$(gum input --prompt "GitHub username: ")"
    github_token="$(gum input --prompt "PAT_BACKBONE_DEPLOY token: " --password)"

    if [[ -z "$github_username" || -z "$github_token" ]]; then
        log_error "GitHub username and PAT_BACKBONE_DEPLOY are required."
        exit 1
    fi

    mkdir -p "$settings_dir"
    if [[ -f "$settings_file" ]]; then
        backup_file="${settings_file}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$settings_file" "$backup_file"
        log_info "Backed up existing settings.xml to $backup_file"
    fi

    cat > "$settings_file" << EOF
<settings>
  <servers>
    <server>
      <id>ghp-kit</id>
      <username>${github_username}</username>
      <password>${github_token}</password>
    </server>
    <server>
      <id>ghp-community</id>
      <username>${github_username}</username>
      <password>${github_token}</password>
    </server>
  </servers>
</settings>
EOF

    log_info "Maven settings configured at ${settings_file}"
}

main "$@"
