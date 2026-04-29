#!/usr/bin/env bash

AI_SWITCH_VERSION="0.1.0"
AI_SWITCH_APP_NAME="ai-switch"
AI_SWITCH_CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/ai-switch"
AI_SWITCH_PROFILES_FILE="$AI_SWITCH_CONFIG_ROOT/profiles.json"
AI_SWITCH_STATE_FILE="$AI_SWITCH_CONFIG_ROOT/state.json"
AI_SWITCH_ENV_DIR="$AI_SWITCH_CONFIG_ROOT/env"
AI_SWITCH_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ai_info() {
    printf "%s\n" "$1"
}

ai_warn() {
    printf "%s\n" "$1" >&2
}

ai_die() {
    printf "%s\n" "$1" >&2
    exit 1
}

ai_has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

ai_require_cmd() {
    ai_has_cmd "$1" || ai_die "$2"
}

ai_run_privileged() {
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

ai_prompt_required() {
    local label="$1"
    local value=""
    while [[ -z "$value" ]]; do
        read -r -p "$label: " value
    done
    printf "%s\n" "$value"
}

ai_prompt_default() {
    local label="$1"
    local default_value="$2"
    local value=""
    read -r -p "$label [$default_value]: " value
    printf "%s\n" "${value:-$default_value}"
}

ai_normalize_provider() {
    case "${1:-openai-compatible}" in
        openai|openai-compatible|openai_compatible) printf "openai-compatible\n" ;;
        gemini|google|google-gemini) printf "gemini\n" ;;
        ollama|local-ollama) printf "ollama\n" ;;
        openrouter) printf "openrouter\n" ;;
        anthropic) printf "anthropic\n" ;;
        *) printf "%s\n" "$1" ;;
    esac
}

ai_normalize_target() {
    case "${1:-codex}" in
        codex) printf "codex\n" ;;
        gemini) printf "gemini\n" ;;
        claude) printf "claude\n" ;;
        deepseek) printf "deepseek\n" ;;
        *) printf "%s\n" "$1" ;;
    esac
}
