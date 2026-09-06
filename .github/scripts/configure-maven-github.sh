#!/usr/bin/env bash
set -euo pipefail

# configure-maven-github.sh
# Type: executable
# Configure Maven settings.xml to use GitHub Packages with the deploy token.

# ---- Functions --------------------------------------------------------------

validate_inputs() {
    if [[ -z "${GITHUB_MAVEN_USERNAME:-}" ]]; then
        echo "GITHUB_MAVEN_USERNAME must be set for Maven GitHub credentials." >&2
        exit 1
    fi

    if [[ -z "${GITHUB_MAVEN_TOKEN:-}" ]]; then
        echo "GITHUB_MAVEN_TOKEN must be set for Maven GitHub credentials." >&2
        exit 1
    fi
}

# ---- Main -------------------------------------------------------------------

main() {
    validate_inputs

    mkdir -p "${HOME}/.m2"

    cat > "${HOME}/.m2/settings.xml" << EOF
<settings>
  <servers>
    <server>
      <id>github</id>
      <username>${GITHUB_MAVEN_USERNAME}</username>
      <password>${GITHUB_MAVEN_TOKEN}</password>
    </server>
  </servers>
</settings>
EOF
}

main "$@"
