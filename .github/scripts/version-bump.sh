#!/usr/bin/env bash
set -euo pipefail

# version-bump.sh
# Type: executable
# Check and bump version using Commitizen.

# ---- Constants --------------------------------------------------------------

readonly COMMITIZEN_NO_BUMP_EXIT=21

# ---- Functions --------------------------------------------------------------

# ---- Main -------------------------------------------------------------------

main() {
    local github_output="${GITHUB_OUTPUT:-/dev/stdout}"
    local current_version next_version bump_log bump_exit get_next_exit tag existing_sha

    git fetch --tags
    git checkout main
    git pull --ff-only origin main

    current_version=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
    echo "current_version=$current_version" >> "$github_output"
    echo "Current version: $current_version"

    sed -i "s/^version = \".*\"/version = \"$current_version\"/" .cz.toml

    # --yes: when no tag exists for the configured version (e.g. fresh 0.0.0 line),
    # commitizen otherwise prompts "Is this the first tag?" and fails in non-TTY CI.
    set +e
    next_version=$(LEFTHOOK=0 cz bump --get-next --yes 2> /dev/null)
    get_next_exit=$?
    set -e

    if [ "$get_next_exit" -eq "$COMMITIZEN_NO_BUMP_EXIT" ] || [ -z "$next_version" ]; then
        echo "No version bump needed - no eligible commits found."
        echo "bumped=false" >> "$github_output"
        echo "next_version=$current_version" >> "$github_output"
        exit 0
    fi

    if [ "$get_next_exit" -ne 0 ]; then
        echo "::error::commitizen --get-next failed (exit ${get_next_exit})"
        exit "$get_next_exit"
    fi

    echo "Next version: ${next_version}"

    tag="v${next_version}"
    if git rev-parse "${tag}^{commit}" > /dev/null 2>&1; then
        existing_sha=$(git rev-parse "${tag}^{commit}")
        echo "::error::Tag ${tag} already exists at ${existing_sha}."
        echo "::error::Orphaned release tags from an older version line can block semver bumps."
        echo "::error::Delete conflicting tags on GitHub, then re-run this workflow."
        exit 1
    fi

    set +e
    bump_log=$(LEFTHOOK=0 cz bump --yes --changelog --version-files-only 2>&1)
    bump_exit=$?
    set -e
    echo "$bump_log"

    if [ "$bump_exit" -eq "$COMMITIZEN_NO_BUMP_EXIT" ]; then
        echo "No version bump needed - no eligible commits found."
        echo "bumped=false" >> "$github_output"
        echo "next_version=$current_version" >> "$github_output"
        exit 0
    fi

    if [ "$bump_exit" -ne 0 ]; then
        echo "::error::commitizen bump failed (exit ${bump_exit})"
        exit "$bump_exit"
    fi

    next_version=$(grep '^version = ' .cz.toml | sed 's/^version = "\(.*\)"/\1/')
    echo "Version bumped: ${current_version} -> ${next_version}"

    mvn versions:set -DnewVersion="${next_version}" -DgenerateBackupPoms=false
    mvn versions:commit

    # Stage only version/changelog artifacts — never git add -A.
    # Include root pom.xml explicitly: some Git versions' '**/pom.xml' pathspec
    # matches nested modules only and skips the aggregator POM.
    git add -- .cz.toml CHANGELOG.md pom.xml '**/pom.xml'
    # [skip actions] is GitHub-native; it must stay in this message so 02 does not re-run on service POM updates
    git commit -m "$(
        cat << EOF
chore(release): version ${next_version}. See

https://github.com/get-backbone/backbone-platform/blob/v${next_version}/CHANGELOG.md

[skip actions]
EOF
    )" --signoff --no-verify
    git tag -s "v${next_version}" -m "Release v${next_version}"

    echo "bumped=true" >> "$github_output"
    echo "next_version=${next_version}" >> "$github_output"
}

main "$@"
