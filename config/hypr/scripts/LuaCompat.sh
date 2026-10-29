#!/bin/bash
# Helpers for running with either hyprland.lua or the legacy hyprland.conf.
# With a Lua config `hyprctl keyword` is disabled and `hyprctl dispatch` takes Lua.
#
# Source it:   . "$HOME/.config/hypr/scripts/LuaCompat.sh"; if hypr_is_lua; then ...
# Or run it:   LuaCompat.sh workspace e+1
#              LuaCompat.sh exit

hypr_is_lua() {
    ! hyprctl eval 'return' 2>/dev/null | grep -q "only supported with the lua"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "$1" in
    workspace)
        if hypr_is_lua; then
            hyprctl dispatch "hl.dsp.focus({ workspace = \"$2\" })"
        else
            hyprctl dispatch workspace "$2"
        fi
        ;;
    exit)
        if hypr_is_lua; then
            hyprctl dispatch "hl.dsp.exit()"
        else
            hyprctl dispatch exit
        fi
        ;;
    *)
        echo "usage: $0 {workspace <ws>|exit}" >&2
        exit 1
        ;;
    esac
fi
