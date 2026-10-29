#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For disabling touchpad.
# Edit the Touchpad_Device on ~/.config/hypr/UserConfigs/Laptops.conf according to your system
# use hyprctl devices to get your system touchpad device name
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109

notif="$HOME/.config/swaync/images/ja.png"

export STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"
. "$HOME/.config/hypr/scripts/LuaCompat.sh"

set_touchpad() {
    if hypr_is_lua; then
        hyprctl eval "kool.set_touchpad($1)"
    else
        hyprctl keyword '$TOUCHPAD_ENABLED' "$1" -r
    fi
}

enable_touchpad() {
    printf "true" >"$STATUS_FILE"
    notify-send -u low -i $notif  " Enabling" " touchpad"
    set_touchpad true
}

disable_touchpad() {
    printf "false" >"$STATUS_FILE"
    notify-send -u low -i $notif " Disabling" " touchpad"
    set_touchpad false
}

if ! [ -f "$STATUS_FILE" ]; then
  enable_touchpad
else
  if [ $(cat "$STATUS_FILE") = "true" ]; then
    disable_touchpad
  elif [ $(cat "$STATUS_FILE") = "false" ]; then
    enable_touchpad
  fi
fi
