#!/bin/bash
# Shared help interface for all scripts.
# Source with: source "$HOME/.local/lib/help.sh"
# Then:  check_help "$1" && show_help "description" "extra details" && exit 0

show_help() {
    local script_name
    script_name="$(basename "${BASH_SOURCE[1]:-$0}")"
    local description="$1"
    shift

    printf '%s - %s\n\nUsage: %s [-h|--help]\n' "$script_name" "$description" "$script_name"
    if [[ $# -gt 0 ]]; then
        printf '\n%s\n' "$*"
    fi
}

check_help() {
    case "${1:-}" in
        -h|--help) return 0 ;;
        *) return 1 ;;
    esac
}
