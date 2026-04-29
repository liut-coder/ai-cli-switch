#!/usr/bin/env bash

init_store() {
    mkdir -p "$AI_SWITCH_CONFIG_ROOT" "$AI_SWITCH_ENV_DIR"
    [[ -f "$AI_SWITCH_PROFILES_FILE" ]] || printf '{}\n' > "$AI_SWITCH_PROFILES_FILE"
    [[ -f "$AI_SWITCH_STATE_FILE" ]] || printf '{"current_profile":"","current_target":"codex"}\n' > "$AI_SWITCH_STATE_FILE"
}

profiles_count() {
    jq 'length' "$AI_SWITCH_PROFILES_FILE"
}

profile_exists() {
    local name="$1"
    jq -e --arg name "$name" 'has($name)' "$AI_SWITCH_PROFILES_FILE" >/dev/null
}

get_profile_json() {
    local name="$1"
    jq -e --arg name "$name" '.[$name]' "$AI_SWITCH_PROFILES_FILE"
}

show_profile_detail() {
    local name="$1"
    local profile
    profile="$(get_profile_json "$name")"
    printf "name=%s\n" "$name"
    printf "provider=%s\n" "$(jq -r '.provider' <<<"$profile")"
    printf "model=%s\n" "$(jq -r '.model' <<<"$profile")"
    printf "base_url=%s\n" "$(jq -r '.base_url' <<<"$profile")"
    printf "api_key=%s\n" "$(jq -r '.api_key' <<<"$profile")"
    printf "targets=%s\n" "$(jq -c '.targets' <<<"$profile")"
}

save_profile() {
    local name="$1"
    local provider="$2"
    local model="$3"
    local base_url="$4"
    local api_key="$5"
    local targets_json="$6"

    provider="$(ai_normalize_provider "$provider")"

    jq \
        --arg name "$name" \
        --arg provider "$provider" \
        --arg model "$model" \
        --arg base_url "$base_url" \
        --arg api_key "$api_key" \
        --argjson targets "$targets_json" \
        '.[$name] = {
            name:$name,
            provider:$provider,
            model:$model,
            base_url:$base_url,
            api_key:$api_key,
            targets:$targets
        }' \
        "$AI_SWITCH_PROFILES_FILE" > "${AI_SWITCH_PROFILES_FILE}.tmp"
    mv "${AI_SWITCH_PROFILES_FILE}.tmp" "$AI_SWITCH_PROFILES_FILE"
}

update_profile() {
    local name="$1"
    local provider="$2"
    local model="$3"
    local base_url="$4"
    local api_key="$5"
    local targets_json="$6"
    local profile

    profile_exists "$name" || ai_die "Profile '$name' 不存在"
    profile="$(get_profile_json "$name")"

    provider="${provider:-$(jq -r '.provider' <<<"$profile")}"
    model="${model:-$(jq -r '.model' <<<"$profile")}"
    base_url="${base_url:-$(jq -r '.base_url' <<<"$profile")}"
    api_key="${api_key:-$(jq -r '.api_key' <<<"$profile")}"
    targets_json="${targets_json:-$(jq -c '.targets' <<<"$profile")}"

    save_profile "$name" "$provider" "$model" "$base_url" "$api_key" "$targets_json"
}

delete_profile() {
    local name="$1"
    profile_exists "$name" || ai_die "Profile '$name' 不存在"
    jq --arg name "$name" 'del(.[$name])' "$AI_SWITCH_PROFILES_FILE" > "${AI_SWITCH_PROFILES_FILE}.tmp"
    mv "${AI_SWITCH_PROFILES_FILE}.tmp" "$AI_SWITCH_PROFILES_FILE"
}

list_profiles() {
    if [[ "$(profiles_count)" -eq 0 ]]; then
        ai_warn "还没有保存任何 profile"
        return
    fi

    jq -r 'to_entries[] | [.key, .value.provider, .value.model, (.value.targets | join(","))] | @tsv' "$AI_SWITCH_PROFILES_FILE" |
    while IFS=$'\t' read -r name provider model targets; do
        printf "%s\t%s\t%s\t%s\n" "$name" "$provider" "$model" "$targets"
    done
}

get_current_profile() {
    jq -r '.current_profile // ""' "$AI_SWITCH_STATE_FILE"
}

set_current_profile() {
    local name="$1"
    jq --arg name "$name" '.current_profile = $name' "$AI_SWITCH_STATE_FILE" > "${AI_SWITCH_STATE_FILE}.tmp"
    mv "${AI_SWITCH_STATE_FILE}.tmp" "$AI_SWITCH_STATE_FILE"
}

get_current_target() {
    jq -r '.current_target // "codex"' "$AI_SWITCH_STATE_FILE"
}

set_current_target() {
    local target
    target="$(ai_normalize_target "$1")"
    jq --arg target "$target" '.current_target = $target' "$AI_SWITCH_STATE_FILE" > "${AI_SWITCH_STATE_FILE}.tmp"
    mv "${AI_SWITCH_STATE_FILE}.tmp" "$AI_SWITCH_STATE_FILE"
}

write_current_env() {
    local name="$1"
    local target="$2"
    local provider="$3"
    local base_url="$4"
    local api_key="$5"
    local model="$6"
    local env_file="$AI_SWITCH_ENV_DIR/current.env"

    cat > "$env_file" <<EOF
export AI_SWITCH_PROFILE='$name'
export AI_SWITCH_TARGET='$target'
export OPENAI_BASE_URL='$base_url'
export OPENAI_API_KEY='$api_key'
export OPENAI_MODEL='$model'
EOF

    case "$(ai_normalize_provider "$provider")" in
        gemini)
            cat >> "$env_file" <<EOF
export GEMINI_API_KEY='$api_key'
export GOOGLE_API_KEY='$api_key'
EOF
            ;;
        *)
            :
            ;;
    esac
}
