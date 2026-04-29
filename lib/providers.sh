#!/usr/bin/env bash

provider_default_model() {
    case "$(ai_normalize_provider "$1")" in
        gemini) printf "gemini-2.5-flash\n" ;;
        ollama) printf "qwen2.5-coder:latest\n" ;;
        anthropic) printf "claude-sonnet-4-20250514\n" ;;
        *) printf "gpt-5.4\n" ;;
    esac
}

provider_default_base_url() {
    case "$(ai_normalize_provider "$1")" in
        gemini) printf "https://generativelanguage.googleapis.com/v1beta/openai\n" ;;
        ollama) printf "http://127.0.0.1:11434/v1\n" ;;
        openrouter) printf "https://openrouter.ai/api/v1\n" ;;
        openai-compatible) printf "https://api.openai.com/v1\n" ;;
        anthropic) printf "https://api.anthropic.com\n" ;;
        *) printf "\n" ;;
    esac
}

provider_default_targets_json() {
    case "$(ai_normalize_provider "$1")" in
        gemini) printf '["codex","gemini","claude"]\n' ;;
        anthropic) printf '["claude"]\n' ;;
        *) printf '["codex","claude"]\n' ;;
    esac
}

provider_supports_target() {
    local provider target
    provider="$(ai_normalize_provider "$1")"
    target="$(ai_normalize_target "$2")"

    case "$target" in
        codex)
            case "$provider" in
                anthropic) return 1 ;;
                *) return 0 ;;
            esac
            ;;
        gemini)
            [[ "$provider" == "gemini" ]] && return 0 || return 1
            ;;
        claude)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

template_files() {
    find "$AI_SWITCH_SCRIPT_DIR/templates" -maxdepth 1 -type f -name '*.json' | sort
}
