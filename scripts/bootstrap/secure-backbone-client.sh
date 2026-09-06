#!/usr/bin/env bash
set -euo pipefail

# secure-backbone-client.sh
# Type: executable
# One-time setup on a client host: create backbone user/group and secure /etc/backbone-config
# (licence file and directory only). Run from repo root. Requires sudo.
# Prerequisite: licence file already at /etc/backbone-config/backbone-licence.
# Usage: task bootstrap:licence-secure

# ---- Constants --------------------------------------------------------------

readonly CONFIG_DIR=/etc/backbone-config

# ---- Functions --------------------------------------------------------------

create_backbone_user_macos() {
    echo "Ensuring group backbone (gid 550)..."
    if ! dscl . -read /Groups/backbone > /dev/null 2>&1; then
        sudo dscl . -create /Groups/backbone
        sudo dscl . -create /Groups/backbone gid 550
    fi

    echo "Ensuring user backbone (uid 550)..."
    if ! dscl . -read /Users/backbone > /dev/null 2>&1; then
        sudo dscl . -create /Users/backbone
        sudo dscl . -create /Users/backbone UserShell /usr/bin/false
        sudo dscl . -create /Users/backbone RealName "Backbone Service User"
        sudo dscl . -create /Users/backbone UniqueID 550
        sudo dscl . -create /Users/backbone PrimaryGroupID 550
    fi
}

create_backbone_user_linux() {
    echo "Creating group backbone (gid 550)..."
    sudo groupadd --gid 550 backbone 2> /dev/null || true

    echo "Creating user backbone (uid 550)..."
    sudo useradd --system --uid 550 --gid backbone --shell /usr/sbin/nologin --comment "Backbone Service User" backbone 2> /dev/null || true
}

secure_client_host() {
    echo "Securing /etc/backbone-config (client host)..."
    sudo chown 0:550 "$CONFIG_DIR/backbone-licence"
    sudo chmod 640 "$CONFIG_DIR/backbone-licence"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        sudo xattr -c "$CONFIG_DIR/backbone-licence" 2> /dev/null || true
    fi
    sudo chown 0:550 "$CONFIG_DIR"
    sudo chmod 750 "$CONFIG_DIR"
}

# ---- Main -------------------------------------------------------------------

main() {
    if [[ ! -f "$CONFIG_DIR/backbone-licence" ]]; then
        echo "Error: $CONFIG_DIR/backbone-licence not found. Install the licence file first (see docs/getting-started/onboarding.md)." >&2
        exit 1
    fi

    case "$(uname -s)" in
        Darwin)
            create_backbone_user_macos
            ;;
        Linux)
            create_backbone_user_linux
            ;;
        *)
            echo "Unsupported OS. Use macOS or Linux." >&2
            exit 1
            ;;
    esac

    secure_client_host

    echo "Done. Add each user who will run the app to the backbone group."
}

main "$@"
