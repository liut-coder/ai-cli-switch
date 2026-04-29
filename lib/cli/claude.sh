#!/usr/bin/env bash

ensure_claude_command_shared() {
    ai_has_cmd claude && return 0
    return 1
}

install_claude_target() {
    install_node_runtime_shared
    ai_require_cmd npm "npm 不可用"

    if npm install -g @anthropic-ai/claude-code; then
        :
    else
        ai_run_privileged npm install -g @anthropic-ai/claude-code
    fi

    hash -r
    ensure_claude_command_shared || true
    ai_require_cmd claude "Claude Code 安装后仍不可用"
    ai_info "Claude Code 已安装"
}

launch_claude_target() {
    ai_require_cmd claude "未检测到 claude 命令"
    local env_file="$AI_SWITCH_ENV_DIR/current.env"
    if [[ -f "$env_file" ]]; then
        set +u
        # shellcheck disable=SC1090
        . "$env_file"
        set -u
    fi
    exec claude
}

apply_claude_target() {
    local name="$1"
    local profile provider model base_url api_key small_model env_file

    profile_exists "$name" || ai_die "Profile '$name' 不存在"
    profile="$(get_profile_json "$name")"
    provider="$(jq -r '.provider' <<<"$profile")"
    model="$(jq -r '.model' <<<"$profile")"
    base_url="$(jq -r '.base_url' <<<"$profile")"
    api_key="$(jq -r '.api_key' <<<"$profile")"
    small_model="$(jq -r '.small_model // ""' <<<"$profile")"
    [[ -n "$small_model" ]] || small_model="$model"

    write_current_env "$name" "claude" "$provider" "$base_url" "$api_key" "$model"
    env_file="$AI_SWITCH_ENV_DIR/current.env"
    cat >> "$env_file" <<EOF
export ANTHROPIC_BASE_URL='$base_url'
export ANTHROPIC_API_KEY='$api_key'
export ANTHROPIC_AUTH_TOKEN='$api_key'
export ANTHROPIC_MODEL='$model'
export ANTHROPIC_SMALL_FAST_MODEL='$small_model'
export ENABLE_TOOL_SEARCH='true'
EOF

    set_current_profile "$name"
    set_current_target "claude"
    ai_info "已将 profile '$name' 应用到 claude"
    ai_info "  ANTHROPIC_BASE_URL=$base_url"
    ai_info "  ANTHROPIC_MODEL=$model"
    ai_info "  ANTHROPIC_SMALL_FAST_MODEL=$small_model"
    ai_info "提示: 运行 'source $env_file' 或使用 --launch claude 启动"
}
