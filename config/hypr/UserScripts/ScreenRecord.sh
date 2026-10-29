#!/usr/bin/env bash
# Toggle a region screen recording with wf-recorder (SUPER + SHIFT + R)

iDIR="$HOME/.config/swaync/icons"
recordingsDir="$HOME/Videos/Recordings"
notify="notify-send -h string:x-canonical-private-synchronous:record-notify"

if pgrep -x wf-recorder >/dev/null; then
    pkill -INT -x wf-recorder
    $notify -i "$iDIR/picture.png" " Screen recording" " Saved to $recordingsDir"
    exit 0
fi

if ! command -v wf-recorder >/dev/null; then
    $notify -u critical " Screen recording" " wf-recorder is not installed (sudo pacman -S wf-recorder)"
    exit 1
fi

region=$(slurp) || exit 0

mkdir -p "$recordingsDir"
file="$recordingsDir/recording-$(date +%F-%H%M%S).mp4"

$notify -i "$iDIR/timer.png" " Screen recording" " Started - SUPER + SHIFT + R to stop"
setsid -f wf-recorder -g "$region" -f "$file" >/dev/null 2>&1
