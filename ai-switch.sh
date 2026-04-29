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
    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --list-profiles)
            init_store
            list_profiles
            ;;
        --add-profile)
            init_store
            [[ $# -eq 7 ]] || ai_die "用法: --add-profile NAME PROVIDER MODEL BASE_URL API_KEY TARGETS"
            save_profile "$2" "$3" "$4" "$5" "$6" "$7"
            ai_info "已保存 profile '$2'"
            ;;
        --import-template)
            init_store
            [[ $# -eq 4 ]] || ai_die "用法: --import-template TEMPLATE_NAME PROFILE_NAME API_KEY"
            import_template_noninteractive "$2" "$3" "$4"
            ;;
        --select-profile)
            init_store
            [[ $# -eq 2 ]] || ai_die "用法: --select-profile NAME"
            profile_exists "$2" || ai_die "Profile '$2' 不存在"
            set_current_profile "$2"
            show_current_state
            ;;
        --delete-profile)
            init_store
            [[ $# -eq 2 ]] || ai_die "用法: --delete-profile NAME"
            delete_profile "$2"
            ai_info "已删除 profile '$2'"
            ;;
        --select-target)
            init_store
            [[ $# -eq 2 ]] || ai_die "用法: --select-target TARGET"
            set_current_target "$2"
            show_current_state
            ;;
        --show-current)
            init_store
            show_current_state
            ;;
        --apply)
            init_store
            apply_profile_by_name "${2:-}"
            ;;
        --install)
            init_store
            install_target_by_name "${2:-}"
            ;;
        --launch)
            init_store
            launch_target_by_name "${2:-}"
            ;;
        --test)
            init_store
            test_profile_by_name "${2:-}"
            ;;
        "")
            init_store
            show_main_menu
            ;;
        *)
            ai_die "未知参数: $1，使用 --help 查看帮助"
            ;;
    esac
}

main "$@"
