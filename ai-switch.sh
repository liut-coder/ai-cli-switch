#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/core.sh
. "$SCRIPT_DIR/lib/core.sh"
# shellcheck source=lib/store.sh
. "$SCRIPT_DIR/lib/store.sh"
# shellcheck source=lib/providers.sh
. "$SCRIPT_DIR/lib/providers.sh"
# shellcheck source=lib/ui.sh
. "$SCRIPT_DIR/lib/ui.sh"
# shellcheck source=lib/cli/codex.sh
. "$SCRIPT_DIR/lib/cli/codex.sh"
# shellcheck source=lib/cli/gemini.sh
. "$SCRIPT_DIR/lib/cli/gemini.sh"

main() {
    init_store
    show_main_menu
}

main "$@"
