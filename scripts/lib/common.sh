#!/usr/bin/env bash
# common.sh
# Type: module (source only — do not execute directly)
# Shared utilities for backbone-core shell scripts: CLI checks, logging, paths, .envrc.local updates.
#
# Prerequisite: gum on PATH when calling log_* or require_cli.

# ---- Functions --------------------------------------------------------------

# -- OS detection and install hints -------------------------------------------

# Returns OS family for install hints: darwin, amzn-linux, linux, or unknown.
detect_os_family() {
    case "$(uname -s)" in
        Darwin) echo darwin ;;
        Linux)
            if [[ -f /etc/os-release ]]; then
                # shellcheck disable=SC1091
                source /etc/os-release
                if [[ "${ID:-}" == "amzn" ]]; then
                    echo amzn-linux
                    return 0
                fi
            fi
            echo linux
            ;;
        *) echo unknown ;;
    esac
}

# Returns an OS-appropriate install hint for a CLI tool (stdout).
install_hint() {
    local cmd="$1"
    local os
    os="$(detect_os_family)"

    case "${os}" in
        darwin) install_hint_darwin "${cmd}" ;;
        amzn-linux) install_hint_amzn_linux "${cmd}" ;;
        *)
            install_hint_generic "${cmd}"
            ;;
    esac
}

install_hint_darwin() {
    local cmd="$1"
    case "${cmd}" in
        gum) echo "Install with: brew install gum" ;;
        gh) echo "Install with: brew install gh" ;;
        jq) echo "Install with: brew install jq" ;;
        yq) echo "Install with: brew install yq" ;;
        pwgen) echo "Install with: brew install pwgen" ;;
        k6) echo "Install with: brew install k6" ;;
        openssl) echo "Install with: brew install openssl" ;;
        envsubst | gettext) echo "Install with: brew install gettext" ;;
        jbang) echo "Install with: brew install jbang" ;;
        docker) echo "Install with: brew install --cask orbstack (or Docker Desktop)" ;;
        aws | awscli) echo "Install AWS CLI: https://aws.amazon.com/cli/" ;;
        awslocal) echo "Install with: brew install awscli-local" ;;
        curl) echo "curl is usually pre-installed on macOS" ;;
        sed) echo "sed is usually pre-installed on macOS" ;;
        lsof) echo "lsof is usually pre-installed on macOS" ;;
        mvn | mvnd) echo "Install with: task bootstrap:toolchain (SDKMAN)" ;;
        task) echo "Install with: brew install go-task" ;;
        quarkus) echo "Install with: brew install quarkusio/tap/quarkus" ;;
        *)
            install_hint_generic "${cmd}"
            ;;
    esac
}

install_hint_amzn_linux() {
    local cmd="$1"
    case "${cmd}" in
        gum | pwgen) echo "Install with: sudo dnf install ${cmd} (Charm repo; task bootstrap:toolchain)" ;;
        gh) echo "Install with: task bootstrap:toolchain (GitHub CLI RPM repo)" ;;
        jq | gettext | openssl | shellcheck)
            echo "Install with: sudo dnf install ${cmd} (or task bootstrap:toolchain)"
            ;;
        envsubst) echo "Install with: sudo dnf install gettext (provides envsubst)" ;;
        k6) echo "Install with: task bootstrap:toolchain (k6 RPM repo)" ;;
        jbang | yq | shfmt | lefthook | trufflehog | direnv)
            echo "Install with: task bootstrap:toolchain"
            ;;
        aws | awscli) echo "Install AWS CLI: https://aws.amazon.com/cli/ (or sudo dnf install awscli)" ;;
        awslocal) echo "Install with: python3 -m pip install --user awscli-local" ;;
        curl | sed | lsof) echo "${cmd} is usually pre-installed on Amazon Linux" ;;
        mvn | mvnd) echo "Install with: task bootstrap:toolchain (SDKMAN)" ;;
        task) echo "Install with: task bootstrap:toolchain or https://taskfile.dev/installation/" ;;
        quarkus) echo "Install with: task bootstrap:toolchain (jbang app install quarkus)" ;;
        docker) echo "Install with: sudo dnf install docker (task bootstrap:toolchain)" ;;
        *)
            install_hint_generic "${cmd}"
            ;;
    esac
}

install_hint_generic() {
    local cmd="$1"
    echo "Install ${cmd}; see docs/getting-started/onboarding.md (Required tooling)"
}

# Require a CLI tool to be available on PATH. Exit 1 if not found.
require_cli() {
    local cmd="$1"
    local install_hint_text="${2:-$(install_hint "$cmd")}"

    if ! command -v "$cmd" &> /dev/null; then
        gum log --level error "$cmd is required but not installed."
        if [[ -n "$install_hint_text" ]]; then
            echo "$install_hint_text" >&2
        fi
        exit 1
    fi
}

# -- Logging (requires gum) ----------------------------------------------------

log_error() {
    gum log --level error -- "$1"
}

log_warn() {
    gum log --level warn -- "$1"
}

log_info() {
    gum log --level info -- "$1"
}

# -- Gum UI theme -------------------------------------------------------------
# Shared interactive look: blue border, sky accent, semantic status colours.

: "${GUM_BORDER_FG:=#305CDE}"
: "${GUM_ACCENT_FG:=#93C5FD}"
: "${GUM_MUTED_FG:=#94A3B8}"
: "${GUM_SUCCESS_FG:=#4ADE80}"
: "${GUM_WARN_FG:=#FBBF24}"
: "${GUM_ERROR_FG:=#F87171}"
: "${GUM_PANEL_WIDTH:=60}"

# Wraps text in accent ANSI for embedding inside gum_panel (use with --no-strip-ansi).
gum_accent_text() {
    printf '\033[38;2;147;197;253m%s\033[0m' "$1"
}

# Bordered intro panel. Args: width, then one or more text lines.
gum_panel() {
    local width="$1"
    shift
    gum style --border rounded --padding "1 2" --margin "1" \
        --border-foreground "${GUM_BORDER_FG}" --width "${width}" --no-strip-ansi -- "$@"
}

# Secondary bordered panel using accent foreground (e.g. warnings).
# Args: width, then one or more text lines.
gum_panel_accent() {
    local width="$1"
    shift
    gum style --border rounded --padding "1 2" --margin "0 1 1 1" \
        --border-foreground "${GUM_BORDER_FG}" --foreground "${GUM_ACCENT_FG}" \
        --width "${width}" -- "$@"
}

gum_title() {
    gum style --foreground "${GUM_ACCENT_FG}" --bold -- "$@"
}

gum_header() {
    gum style --foreground "${GUM_MUTED_FG}" --bold -- "$@"
}

gum_muted() {
    gum style --foreground "${GUM_MUTED_FG}" -- "$@"
}

gum_accent() {
    gum style --foreground "${GUM_ACCENT_FG}" -- "$@"
}

gum_success() {
    gum style --foreground "${GUM_SUCCESS_FG}" -- "$@"
}

gum_warn() {
    gum style --foreground "${GUM_WARN_FG}" -- "$@"
}

gum_error() {
    gum style --foreground "${GUM_ERROR_FG}" -- "$@"
}

# -- Path utilities -----------------------------------------------------------

# Returns project root (two levels above SCRIPT_DIR). Caller must set SCRIPT_DIR first.
get_project_root() {
    if [[ -z "${SCRIPT_DIR:-}" ]]; then
        echo "Error: SCRIPT_DIR must be set before calling get_project_root()" >&2
        exit 1
    fi
    cd "$SCRIPT_DIR/../.." && pwd
}

# -- .envrc.local -------------------------------------------------------------

# Updates or appends export KEY="value" in ENVRC_FILE (portable sed via temp file).
update_envrc_key() {
    local key="$1"
    local value="$2"
    local escaped_key escaped_value temp_file last_byte

    if [[ -z "${ENVRC_FILE:-}" ]]; then
        log_error "ENVRC_FILE must be set before calling update_envrc_key"
        return 1
    fi

    # shellcheck disable=SC2016
    escaped_key=$(printf '%s\n' "$key" | sed 's/[[\.*^$()+?{|]/\\&/g')
    escaped_value=$value
    escaped_value=${escaped_value//\\/\\\\}
    escaped_value=${escaped_value//&/\\&}
    escaped_value=${escaped_value//|/\\|}

    if grep -qE "^export ${escaped_key}=" "$ENVRC_FILE" 2> /dev/null; then
        temp_file=$(mktemp)
        sed -E "s|^export ${escaped_key}=.*|export ${key}=\"${escaped_value}\"|" "$ENVRC_FILE" > "$temp_file"
        mv "$temp_file" "$ENVRC_FILE"
    else
        if [[ -s "$ENVRC_FILE" ]]; then
            last_byte=$(tail -c 1 "$ENVRC_FILE" | od -An -tu1 | tr -d ' \n')
            if [[ "$last_byte" != "10" ]] && [[ -n "$last_byte" ]]; then
                printf '\n' >> "$ENVRC_FILE"
            fi
        fi
        printf 'export %s="%s"\n' "$key" "$value" >> "$ENVRC_FILE"
    fi
}

# Removes export KEY=... lines from ENVRC_FILE when present.
remove_envrc_key() {
    local key="$1"
    local escaped_key temp_file

    if [[ -z "${ENVRC_FILE:-}" ]]; then
        log_error "ENVRC_FILE must be set before calling remove_envrc_key"
        return 1
    fi

    [[ -f "$ENVRC_FILE" ]] || return 0

    escaped_key=$(printf '%s\n' "$key" | sed 's/[[\.*^$()+?{|]/\\&/g')
    if ! grep -qE "^export ${escaped_key}=" "$ENVRC_FILE" 2> /dev/null; then
        return 0
    fi

    temp_file=$(mktemp)
    sed -E "/^export ${escaped_key}=/d" "$ENVRC_FILE" > "$temp_file"
    mv "$temp_file" "$ENVRC_FILE"
}
