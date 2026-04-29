#!/usr/bin/env bash

AI_SWITCH_CODEX_TOML_DIR="$HOME/.codex"
AI_SWITCH_CODEX_TOML_FILE="$AI_SWITCH_CODEX_TOML_DIR/config.toml"

codex_upsert_toml_root_key() {
    local file="$1"
    local key="$2"
    local value="$3"

    if grep -Eq "^${key}[[:space:]]*=" "$file"; then
        sed -i "s|^${key}[[:space:]]*=.*$|${key} = \"${value}\"|" "$file"
    else
        printf "%s = \"%s\"\n%s" "$key" "$value" "$(cat "$file")" > "${file}.tmp"
        mv "${file}.tmp" "$file"
    fi
}

codex_write_toml() {
    local base_url="$1"
    local api_key="$2"
    local model="$3"
    local tmp_file

    mkdir -p "$AI_SWITCH_CODEX_TOML_DIR"
    [[ -f "$AI_SWITCH_CODEX_TOML_FILE" ]] || touch "$AI_SWITCH_CODEX_TOML_FILE"

    codex_upsert_toml_root_key "$AI_SWITCH_CODEX_TOML_FILE" "model_provider" "OpenAI"
    codex_upsert_toml_root_key "$AI_SWITCH_CODEX_TOML_FILE" "model" "$model"

    tmp_file="$(mktemp)"
    awk '
        BEGIN { in_section=0 }
        /^\[model_providers\.OpenAI\]$/ {
            print
            print "name = \"OpenAI\""
            print "base_url = \"__BASE_URL__\""
            print "api_key = \"__API_KEY__\""
            in_section=1
            next
        }
        /^\[/ { in_section=0 }
        in_section && /^name[[:space:]]*=/ { next }
        in_section && /^base_url[[:space:]]*=/ { next }
        in_section && /^api_key[[:space:]]*=/ { next }
        { print }
    ' "$AI_SWITCH_CODEX_TOML_FILE" > "$tmp_file"

    if ! grep -Fq '[model_providers.OpenAI]' "$tmp_file"; then
        {
            printf "\n[model_providers.OpenAI]\n"
            printf "name = \"OpenAI\"\n"
            printf "base_url = \"%s\"\n" "$base_url"
            printf "api_key = \"%s\"\n" "$api_key"
        } >> "$tmp_file"
    else
        sed -i \
            -e "s|__BASE_URL__|$base_url|g" \
            -e "s|__API_KEY__|$api_key|g" \
            "$tmp_file"
    fi

    mv "$tmp_file" "$AI_SWITCH_CODEX_TOML_FILE"
}

install_node_runtime_shared() {
    if ai_has_cmd npm; then
        return 0
    fi

    if ai_has_cmd apt-get; then
        ai_run_privileged apt-get update
        ai_run_privileged apt-get install -y nodejs npm
        return 0
    fi

    if ai_has_cmd dnf; then
        ai_run_privileged dnf install -y nodejs npm
        return 0
    fi

    if ai_has_cmd yum; then
        ai_run_privileged yum install -y nodejs npm
        return 0
    fi

    if ai_has_cmd brew; then
        brew install node
        return 0
    fi

    ai_die "无法自动安装 npm。请先手动安装 Node.js 和 npm。"
}

install_codex_target() {
    install_node_runtime_shared
    ai_require_cmd npm "npm 不可用"

    if npm install -g @openai/codex; then
        :
    else
        ai_run_privileged npm install -g @openai/codex
    fi

    hash -r
    ai_require_cmd codex "Codex CLI 安装后仍不可用"
    ai_info "Codex CLI 已安装"
}

launch_codex_target() {
    ai_require_cmd codex "未检测到 codex 命令"
    exec codex
}

apply_codex_target() {
    local name="$1"
    local profile provider model base_url api_key

    profile_exists "$name" || ai_die "Profile '$name' 不存在"
    profile="$(get_profile_json "$name")"
    provider="$(jq -r '.provider' <<<"$profile")"
    model="$(jq -r '.model' <<<"$profile")"
    base_url="$(jq -r '.base_url' <<<"$profile")"
    api_key="$(jq -r '.api_key' <<<"$profile")"

    provider_supports_target "$provider" codex || ai_die "Provider '$provider' 不能直接应用到 codex"

    write_current_env "$name" "codex" "$provider" "$base_url" "$api_key" "$model"

    if ai_has_cmd codex && codex help config >/dev/null 2>&1; then
        codex config set base_url "$base_url" >/dev/null
        codex config set api_key "$api_key" >/dev/null
        codex config set model "$model" >/dev/null
    else
        codex_write_toml "$base_url" "$api_key" "$model"
    fi

    set_current_profile "$name"
    set_current_target "codex"
    ai_info "已将 profile '$name' 应用到 codex"
}
