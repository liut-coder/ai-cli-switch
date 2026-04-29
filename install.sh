#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN_DIR="${TARGET_BIN_DIR:-/usr/local/bin}"
TARGET_LIB_DIR="${TARGET_LIB_DIR:-/usr/local/lib/ai-cli-switch}"
TARGET_MAIN="$TARGET_BIN_DIR/ai-switch"
DEFAULT_BASE_URL="https://raw.githubusercontent.com/liut-coder/ai-cli-switch/main"
DOWNLOAD_BASE_URL="${AI_SWITCH_INSTALL_BASE_URL:-$DEFAULT_BASE_URL}"
TMP_ROOT=""
SCRIPT_SOURCE="${BASH_SOURCE[0]}"

log() {
    printf "%s\n" "$1"
}

run_privileged() {
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

cleanup() {
    if [[ -n "$TMP_ROOT" && -d "$TMP_ROOT" ]]; then
        rm -rf "$TMP_ROOT"
    fi
}

is_local_checkout() {
    [[ -f "$SCRIPT_DIR/ai-switch.sh" && -d "$SCRIPT_DIR/lib" && -d "$SCRIPT_DIR/templates" ]]
}

download_repo_layout() {
    TMP_ROOT="$(mktemp -d /tmp/ai-cli-switch.XXXXXX)"
    mkdir -p "$TMP_ROOT/lib/cli" "$TMP_ROOT/templates"

    curl -fsSL "$DOWNLOAD_BASE_URL/ai-switch.sh" -o "$TMP_ROOT/ai-switch.sh"
    curl -fsSL "$DOWNLOAD_BASE_URL/lib/core.sh" -o "$TMP_ROOT/lib/core.sh"
    curl -fsSL "$DOWNLOAD_BASE_URL/lib/store.sh" -o "$TMP_ROOT/lib/store.sh"
    curl -fsSL "$DOWNLOAD_BASE_URL/lib/providers.sh" -o "$TMP_ROOT/lib/providers.sh"
    curl -fsSL "$DOWNLOAD_BASE_URL/lib/ui.sh" -o "$TMP_ROOT/lib/ui.sh"
    curl -fsSL "$DOWNLOAD_BASE_URL/lib/cli/codex.sh" -o "$TMP_ROOT/lib/cli/codex.sh"
    curl -fsSL "$DOWNLOAD_BASE_URL/lib/cli/gemini.sh" -o "$TMP_ROOT/lib/cli/gemini.sh"
    curl -fsSL "$DOWNLOAD_BASE_URL/lib/cli/claude.sh" -o "$TMP_ROOT/lib/cli/claude.sh"
    curl -fsSL "$DOWNLOAD_BASE_URL/lib/cli/deepseek.sh" -o "$TMP_ROOT/lib/cli/deepseek.sh"
    curl -fsSL "$DOWNLOAD_BASE_URL/templates/gemini-flash.json" -o "$TMP_ROOT/templates/gemini-flash.json"
    curl -fsSL "$DOWNLOAD_BASE_URL/templates/glm-5.1.json" -o "$TMP_ROOT/templates/glm-5.1.json"
    curl -fsSL "$DOWNLOAD_BASE_URL/templates/ollama-local.json" -o "$TMP_ROOT/templates/ollama-local.json"
    curl -fsSL "$DOWNLOAD_BASE_URL/templates/openrouter-free.json" -o "$TMP_ROOT/templates/openrouter-free.json"

    chmod +x "$TMP_ROOT/ai-switch.sh"
}

write_wrapper() {
    local wrapper="$1"
    local target_script="$2"
    local tmp_wrapper

    tmp_wrapper="$(mktemp /tmp/ai-switch-wrapper.XXXXXX)"
    cat > "$tmp_wrapper" <<EOF
#!/usr/bin/env bash
exec "$target_script" "\$@"
EOF
    run_privileged install -m 755 "$tmp_wrapper" "$wrapper"
    rm -f "$tmp_wrapper"
}

install_tree() {
    local source_root="$1"

    run_privileged mkdir -p "$TARGET_BIN_DIR" "$TARGET_LIB_DIR" "$TARGET_LIB_DIR/lib/cli" "$TARGET_LIB_DIR/templates"
    run_privileged install -m 755 "$source_root/ai-switch.sh" "$TARGET_LIB_DIR/ai-switch.sh"
    run_privileged install -m 644 "$source_root/lib/core.sh" "$TARGET_LIB_DIR/lib/core.sh"
    run_privileged install -m 644 "$source_root/lib/store.sh" "$TARGET_LIB_DIR/lib/store.sh"
    run_privileged install -m 644 "$source_root/lib/providers.sh" "$TARGET_LIB_DIR/lib/providers.sh"
    run_privileged install -m 644 "$source_root/lib/ui.sh" "$TARGET_LIB_DIR/lib/ui.sh"
    run_privileged install -m 644 "$source_root/lib/cli/codex.sh" "$TARGET_LIB_DIR/lib/cli/codex.sh"
    run_privileged install -m 644 "$source_root/lib/cli/gemini.sh" "$TARGET_LIB_DIR/lib/cli/gemini.sh"
    run_privileged install -m 644 "$source_root/lib/cli/claude.sh" "$TARGET_LIB_DIR/lib/cli/claude.sh"
    run_privileged install -m 644 "$source_root/lib/cli/deepseek.sh" "$TARGET_LIB_DIR/lib/cli/deepseek.sh"
    run_privileged install -m 644 "$source_root/templates/gemini-flash.json" "$TARGET_LIB_DIR/templates/gemini-flash.json"
    run_privileged install -m 644 "$source_root/templates/glm-5.1.json" "$TARGET_LIB_DIR/templates/glm-5.1.json"
    run_privileged install -m 644 "$source_root/templates/ollama-local.json" "$TARGET_LIB_DIR/templates/ollama-local.json"
    run_privileged install -m 644 "$source_root/templates/openrouter-free.json" "$TARGET_LIB_DIR/templates/openrouter-free.json"
    write_wrapper "$TARGET_MAIN" "$TARGET_LIB_DIR/ai-switch.sh"
}

main() {
    trap cleanup EXIT

    case "$SCRIPT_SOURCE" in
        /dev/fd/*|/proc/self/fd/*)
            download_repo_layout
            install_tree "$TMP_ROOT"
            ;;
        *)
            if is_local_checkout; then
                install_tree "$SCRIPT_DIR"
            else
                download_repo_layout
                install_tree "$TMP_ROOT"
            fi
            ;;
    esac

    log "安装 ai-cli-switch..."
    log "  bin: $TARGET_MAIN"
    log "  lib: $TARGET_LIB_DIR"
    log "安装完成"
}

main "$@"
