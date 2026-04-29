#!/usr/bin/env bash

show_main_menu_text() {
    printf "ai-cli-switch v%s\n\n" "$AI_SWITCH_VERSION"
    printf "当前 Profile: %s\n" "$(get_current_profile)"
    printf "当前 Target: %s\n\n" "$(get_current_target)"
    printf "1) 管理 Profiles\n"
    printf "2) 选择目标 CLI\n"
    printf "3) 应用当前 Profile 到目标 CLI\n"
    printf "4) 启动目标 CLI\n"
    printf "5) 安装/升级 CLI\n"
    printf "6) 模板快速添加\n"
    printf "7) 测试当前 Profile\n"
    printf "0) 退出\n"
}

select_target_interactive() {
    local choice
    printf "1) codex\n"
    printf "2) gemini\n"
    read -r -p "选择 target [1-2]: " choice
    case "$choice" in
        1) printf "codex\n" ;;
        2) printf "gemini\n" ;;
        *) ai_die "无效 target" ;;
    esac
}

select_profile_name_interactive() {
    local names choice index=1
    mapfile -t names < <(jq -r 'keys[]' "$AI_SWITCH_PROFILES_FILE")
    [[ "${#names[@]}" -gt 0 ]] || ai_die "还没有任何 profile"
    for choice in "${names[@]}"; do
        printf "%d) %s\n" "$index" "$choice" >&2
        index=$((index + 1))
    done
    read -r -p "选择 profile [1-${#names[@]}]: " choice
    [[ "$choice" =~ ^[0-9]+$ ]] || ai_die "输入无效"
    (( choice >= 1 && choice <= ${#names[@]} )) || ai_die "超出范围"
    printf "%s\n" "${names[$((choice - 1))]}"
}

add_profile_interactive() {
    local name provider model base_url api_key targets_json target_choice

    name="$(ai_prompt_required 'Profile 名称')"
    provider="$(ai_prompt_default 'Provider' 'openai-compatible')"
    provider="$(ai_normalize_provider "$provider")"
    model="$(ai_prompt_default '模型' "$(provider_default_model "$provider")")"
    base_url="$(ai_prompt_default 'Base URL' "$(provider_default_base_url "$provider")")"
    if [[ "$provider" == "ollama" ]]; then
        read -r -p "API Key [Ollama 可留空]: " api_key
    else
        api_key="$(ai_prompt_required 'API Key')"
    fi

    printf "默认允许的 target:\n"
    printf "1) 使用 provider 默认值\n"
    printf "2) 仅 codex\n"
    printf "3) 仅 gemini\n"
    read -r -p "请选择 [1-3, 默认 1]: " target_choice
    case "${target_choice:-1}" in
        1) targets_json="$(provider_default_targets_json "$provider")" ;;
        2) targets_json='["codex"]' ;;
        3) targets_json='["gemini"]' ;;
        *) targets_json="$(provider_default_targets_json "$provider")" ;;
    esac

    save_profile "$name" "$provider" "$model" "$base_url" "$api_key" "$targets_json"
    ai_info "已保存 profile '$name'"
}

edit_profile_interactive() {
    local name="$1"
    local profile provider model base_url api_key targets_json target_choice

    profile="$(get_profile_json "$name")"
    provider="$(ai_prompt_default 'Provider' "$(jq -r '.provider' <<<"$profile")")"
    provider="$(ai_normalize_provider "$provider")"
    model="$(ai_prompt_default '模型' "$(jq -r '.model' <<<"$profile")")"
    base_url="$(ai_prompt_default 'Base URL' "$(jq -r '.base_url' <<<"$profile")")"
    if [[ "$provider" == "ollama" ]]; then
        read -r -p "API Key [留空保持不变，可为空]: " api_key
    else
        read -r -p "API Key [留空保持不变]: " api_key
    fi

    printf "目标 targets:\n"
    printf "1) 保持不变\n"
    printf "2) 仅 codex\n"
    printf "3) 仅 gemini\n"
    printf "4) codex + gemini\n"
    read -r -p "请选择 [1-4, 默认 1]: " target_choice
    case "${target_choice:-1}" in
        1) targets_json="" ;;
        2) targets_json='["codex"]' ;;
        3) targets_json='["gemini"]' ;;
        4) targets_json='["codex","gemini"]' ;;
        *) targets_json="" ;;
    esac

    update_profile "$name" "$provider" "$model" "$base_url" "${api_key:-}" "$targets_json"
    ai_info "已更新 profile '$name'"
}

manage_profiles_menu() {
    local choice profile_name

    while true; do
        printf "\nProfiles\n"
        printf "1) 列出 profiles\n"
        printf "2) 新增 profile\n"
        printf "3) 查看 profile 详情\n"
        printf "4) 编辑 profile\n"
        printf "5) 选择当前 profile\n"
        printf "6) 删除 profile\n"
        printf "0) 返回\n"
        read -r -p "选择: " choice
        case "$choice" in
            1) list_profiles ;;
            2) add_profile_interactive ;;
            3) profile_name="$(select_profile_name_interactive)"; show_profile_detail "$profile_name" ;;
            4) profile_name="$(select_profile_name_interactive)"; edit_profile_interactive "$profile_name" ;;
            5) profile_name="$(select_profile_name_interactive)"; set_current_profile "$profile_name"; ai_info "当前 profile: $profile_name" ;;
            6) profile_name="$(select_profile_name_interactive)"; delete_profile "$profile_name"; ai_info "已删除: $profile_name" ;;
            0) return 0 ;;
            *) ai_warn "无效选项" ;;
        esac
    done
}

apply_current_profile() {
    local profile target
    profile="$(get_current_profile)"
    target="$(get_current_target)"
    [[ -n "$profile" ]] || ai_die "当前没有选中 profile"

    case "$target" in
        codex) apply_codex_target "$profile" ;;
        gemini) apply_gemini_target "$profile" ;;
        *) ai_die "不支持的 target: $target" ;;
    esac
}

install_current_target() {
    local target
    target="$(get_current_target)"
    case "$target" in
        codex) install_codex_target ;;
        gemini) install_gemini_target ;;
        *) ai_die "不支持的 target: $target" ;;
    esac
}

launch_current_target() {
    local target
    target="$(get_current_target)"
    case "$target" in
        codex) launch_codex_target ;;
        gemini) launch_gemini_target ;;
        *) ai_die "不支持的 target: $target" ;;
    esac
}

import_template_interactive() {
    local files choice index=1 file name provider model base_url targets_json api_key
    mapfile -t files < <(template_files)
    [[ "${#files[@]}" -gt 0 ]] || ai_die "没有可用模板"
    for file in "${files[@]}"; do
        printf "%d) %s\n" "$index" "$(basename "$file" .json)"
        index=$((index + 1))
    done
    read -r -p "选择模板 [1-${#files[@]}]: " choice
    [[ "$choice" =~ ^[0-9]+$ ]] || ai_die "输入无效"
    (( choice >= 1 && choice <= ${#files[@]} )) || ai_die "超出范围"
    file="${files[$((choice - 1))]}"

    name="$(ai_prompt_required 'Profile 名称')"
    provider="$(jq -r '.provider' "$file")"
    model="$(jq -r '.model' "$file")"
    base_url="$(jq -r '.base_url' "$file")"
    targets_json="$(jq -c '.targets' "$file")"
    if [[ "$provider" == "ollama" ]]; then
        read -r -p "API Key [Ollama 可留空]: " api_key
    else
        api_key="$(ai_prompt_required 'API Key')"
    fi

    save_profile "$name" "$provider" "$model" "$base_url" "$api_key" "$targets_json"
    ai_info "已根据模板导入 profile '$name'"
}

test_current_profile() {
    local profile_json profile provider base_url api_key endpoint http_code
    profile="$(get_current_profile)"
    [[ -n "$profile" ]] || ai_die "当前没有选中 profile"
    profile_json="$(get_profile_json "$profile")"
    provider="$(jq -r '.provider' <<<"$profile_json")"
    base_url="$(jq -r '.base_url' <<<"$profile_json")"
    api_key="$(jq -r '.api_key' <<<"$profile_json")"
    endpoint="${base_url%/}/models"

    ai_require_cmd curl "缺少 curl"
    ai_info "测试 provider '$provider': $endpoint"

    http_code="$(
        curl -sS -o /tmp/ai-switch-test.out -w '%{http_code}' \
            -H "Authorization: Bearer $api_key" \
            -H 'Content-Type: application/json' \
            "$endpoint" || true
    )"

    if [[ "$http_code" == "200" ]]; then
        ai_info "连接成功"
    else
        ai_warn "连接失败: HTTP $http_code"
    fi
}

show_main_menu() {
    local choice
    while true; do
        show_main_menu_text
        read -r -p "选择: " choice
        case "$choice" in
            1) manage_profiles_menu ;;
            2) set_current_target "$(select_target_interactive)"; ai_info "当前 target: $(get_current_target)" ;;
            3) apply_current_profile ;;
            4) launch_current_target ;;
            5) install_current_target ;;
            6) import_template_interactive ;;
            7) test_current_profile ;;
            0) exit 0 ;;
            *) ai_warn "无效选项" ;;
        esac
        printf "\n"
    done
}

show_help() {
    cat <<EOF
Usage: $AI_SWITCH_APP_NAME [option]

Options:
  --list-profiles
  --add-profile NAME PROVIDER MODEL BASE_URL API_KEY TARGETS
  --add-gemini NAME API_KEY [BASE_URL] [MODEL]
  --add-glm NAME API_KEY [BASE_URL] [MODEL]
  --import-template TEMPLATE_NAME PROFILE_NAME API_KEY
  --show-profile NAME
  --update-profile NAME [PROVIDER] [MODEL] [BASE_URL] [API_KEY] [TARGETS]
  --select-profile NAME
  --delete-profile NAME
  --select-target TARGET
  --show-current
  --apply [PROFILE_NAME]
  --install [TARGET]
  --launch [TARGET]
  --test [PROFILE_NAME]
  --help

Notes:
  TARGET 支持: codex, gemini
  TARGETS 传 JSON 数组，例如: '["codex","gemini"]'
  TEMPLATE_NAME 例如: gemini-flash, glm-5.1, ollama-local, openrouter-free
EOF
}

show_current_state() {
    printf "current_profile=%s\n" "$(get_current_profile)"
    printf "current_target=%s\n" "$(get_current_target)"
}

find_template_by_name() {
    local name="$1"
    local file="$AI_SWITCH_SCRIPT_DIR/templates/$name.json"
    [[ -f "$file" ]] || ai_die "模板不存在: $name"
    printf "%s\n" "$file"
}

import_template_noninteractive() {
    local template_name="$1"
    local profile_name="$2"
    local api_key="$3"
    local file provider model base_url targets_json

    file="$(find_template_by_name "$template_name")"
    provider="$(jq -r '.provider' "$file")"
    model="$(jq -r '.model' "$file")"
    base_url="$(jq -r '.base_url' "$file")"
    targets_json="$(jq -c '.targets' "$file")"

    save_profile "$profile_name" "$provider" "$model" "$base_url" "$api_key" "$targets_json"
    ai_info "已导入模板 '$template_name' -> '$profile_name'"
}

apply_profile_by_name() {
    local profile_name="$1"
    [[ -n "$profile_name" ]] || profile_name="$(get_current_profile)"
    [[ -n "$profile_name" ]] || ai_die "当前没有选中 profile"
    set_current_profile "$profile_name"
    apply_current_profile
}

install_target_by_name() {
    local target="${1:-}"
    if [[ -n "$target" ]]; then
        set_current_target "$target"
    fi
    install_current_target
}

launch_target_by_name() {
    local target="${1:-}"
    if [[ -n "$target" ]]; then
        set_current_target "$target"
    fi
    launch_current_target
}

test_profile_by_name() {
    local profile_name="${1:-}"
    if [[ -n "$profile_name" ]]; then
        set_current_profile "$profile_name"
    fi
    test_current_profile
}
