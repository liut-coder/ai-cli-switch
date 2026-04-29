#!/usr/bin/env bash

write_gemini_wrapper_shared() {
    local target="/usr/local/bin/gemini"
    local bin_path="$1"
    local wrapper_source

    wrapper_source="$(mktemp)"
    cat > "$wrapper_source" <<EOF
#!/usr/bin/env bash
exec node "$bin_path" "\$@"
EOF

    ai_run_privileged install -m 755 "$wrapper_source" "$target"
    rm -f "$wrapper_source"
}

ensure_gemini_command_shared() {
    local prefix
    local package_dir=""
    local package_json=""
    local bin_rel=""

    ai_has_cmd gemini && return 0

    prefix="$(npm prefix -g 2>/dev/null || npm config get prefix 2>/dev/null || true)"
    for package_dir in \
        "$prefix/lib/node_modules/@google/gemini-cli" \
        "$prefix/lib/node_modules/@google-dev/gemini-cli" \
        "/usr/lib/node_modules/@google/gemini-cli" \
        "/usr/local/lib/node_modules/@google/gemini-cli"
    do
        package_json="$package_dir/package.json"
        if [[ -f "$package_json" ]]; then
            bin_rel="$(jq -r '.bin.gemini // empty' "$package_json" 2>/dev/null || true)"
            if [[ -z "$bin_rel" ]]; then
                bin_rel="$(jq -r 'if (.bin|type)=="string" then .bin else empty end' "$package_json" 2>/dev/null || true)"
            fi
            if [[ -n "$bin_rel" && -f "$package_dir/$bin_rel" ]]; then
                write_gemini_wrapper_shared "$package_dir/$bin_rel"
                hash -r
                ai_has_cmd gemini && return 0
            fi
        fi
    done

    return 1
}

install_gemini_target() {
    install_node_runtime_shared
    ai_require_cmd npm "npm 不可用"

    if npm install -g @google/gemini-cli; then
        :
    else
        ai_run_privileged npm install -g @google/gemini-cli
    fi

    hash -r
    ensure_gemini_command_shared || true
    ai_require_cmd gemini "Gemini CLI 安装后仍不可用"
    ai_info "Gemini CLI 已安装"
}

launch_gemini_target() {
    ai_require_cmd gemini "未检测到 gemini 命令"
    exec gemini
}

apply_gemini_target() {
    local name="$1"
    local profile provider model base_url api_key

    profile_exists "$name" || ai_die "Profile '$name' 不存在"
    profile="$(get_profile_json "$name")"
    provider="$(jq -r '.provider' <<<"$profile")"
    model="$(jq -r '.model' <<<"$profile")"
    base_url="$(jq -r '.base_url' <<<"$profile")"
    api_key="$(jq -r '.api_key' <<<"$profile")"

    provider_supports_target "$provider" gemini || ai_die "Provider '$provider' 不能直接应用到 gemini"

    write_current_env "$name" "gemini" "$provider" "$base_url" "$api_key" "$model"
    set_current_profile "$name"
    set_current_target "gemini"
    ai_info "已将 profile '$name' 应用到 gemini"
}
