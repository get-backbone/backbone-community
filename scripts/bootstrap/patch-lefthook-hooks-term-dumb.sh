#!/usr/bin/env bash
set -euo pipefail

# patch-lefthook-hooks-term-dumb.sh
# Type: executable
# After lefthook install, prepend TERM=dumb to each generated hook so lipgloss/termenv
# does not send OSC color queries that iTerm2 answers into zsh's input buffer.

# ---- Constants --------------------------------------------------------------

readonly MARKER='# backbone-core: lefthook TERM=dumb (iTerm OSC reply leak workaround)'

# ---- Functions --------------------------------------------------------------

patch_hook() {
    local hook_path="$1"
    if ! grep -q 'call_lefthook' "${hook_path}" 2> /dev/null; then
        return 0
    fi
    if grep -qF "${MARKER}" "${hook_path}"; then
        return 0
    fi
    local tmp
    tmp="$(mktemp)"
    {
        IFS= read -r first_line || true
        printf '%s\n' "${first_line}"
        printf '%s\n' "${MARKER}"
        printf '%s\n' "export TERM=dumb"
        cat
    } < "${hook_path}" > "${tmp}"
    chmod +x "${tmp}"
    mv "${tmp}" "${hook_path}"
}

# ---- Main -------------------------------------------------------------------

main() {
    local repo_root hooks_dir hook_path

    repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    hooks_dir="${repo_root}/.git/hooks"

    if [[ ! -d "${hooks_dir}" ]]; then
        echo "patch-lefthook-hooks-term-dumb: no .git/hooks (not a git checkout?)" >&2
        exit 1
    fi

    shopt -s nullglob
    for hook_path in "${hooks_dir}"/*; do
        [[ -f "${hook_path}" ]] || continue
        patch_hook "${hook_path}"
    done
}

main "$@"
