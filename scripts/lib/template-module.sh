#!/usr/bin/env bash
# module-name.sh
# Type: module (source only — do not execute directly)
# Description of shared functions for callers that source this file.

# ---- Imports ----------------------------------------------------------------

readonly MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${MODULE_DIR}/../lib/common.sh"

# ---- Constants --------------------------------------------------------------

# shared constants visible to sourcing scripts

# ---- Functions --------------------------------------------------------------

# functions for callers via: source "${MODULE_DIR}/module-name.sh"
