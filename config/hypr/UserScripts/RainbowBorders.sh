#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# for rainbow borders animation

function random_hex() {
    random_hex=("0xff$(openssl rand -hex 3)")
    echo $random_hex
}

. "$HOME/.config/hypr/scripts/LuaCompat.sh"

# hyprland.lua does this itself at startup (kool.rainbow_borders)
if hypr_is_lua; then
    hyprctl eval "kool.rainbow_borders()"
    exit
fi

# rainbow colors only for active window
hyprctl keyword general:col.active_border $(random_hex)  $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex)  270deg

# rainbow colors for inactive window (uncomment to take effect)
#hyprctl keyword general:col.inactive_border $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) 270deg