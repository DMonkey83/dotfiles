#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for changing blurs on the fly

notif="$HOME/.config/swaync/images"
. "$HOME/.config/hypr/scripts/LuaCompat.sh"

set_blur() {
	if hypr_is_lua; then
		hyprctl eval "hl.config({ decoration = { blur = { size = $1, passes = $2 } } })"
	else
		hyprctl keyword decoration:blur:size "$1"
		hyprctl keyword decoration:blur:passes "$2"
	fi
}

STATE=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

if [ "${STATE}" == "2" ]; then
	set_blur 2 1
 	notify-send -e -u low -i "$notif/note.png" " Less Blur"
else
	set_blur 5 2
  	notify-send -e -u low -i "$notif/ja.png" " Normal Blur"
fi
