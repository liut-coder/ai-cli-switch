#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${TARGET_DIR:-/usr/local/bin}"
TARGET_MAIN="$TARGET_DIR/ai-switch"

install_file() {
    local src="$1"
    local dst="$2"
    if install -m 755 "$src" "$dst" 2>/dev/null; then
        return 0
    fi
    sudo install -m 755 "$src" "$dst"
}

main() {
    mkdir -p "$TARGET_DIR"
    install_file "$SCRIPT_DIR/ai-switch.sh" "$TARGET_MAIN"
    printf "Installed: %s\n" "$TARGET_MAIN"
}

main "$@"
