#!/usr/bin/env bash
# Shared settings and helpers for the dotfiles scripts. Sourced, not run.

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="$DOTFILES/packages"

# Entries of ~/.config tracked in config/
CONFIG_ITEMS=(
  # Hyprland desktop (JaKooLit Hyprland-Dots + own changes)
  hypr waybar rofi swaync wallust wlogout ags
  # terminals / shell tools
  kitty ghostty fastfetch btop cava lazygit gitui git
  # editor (LazyVim)
  nvim
  # theming
  Kvantum qt5ct qt6ct gtk-3.0 gtk-4.0 nwg-look xsettingsd
  # apps
  swappy flameshot mpv autostart abacus mimeapps.list
)

# Files in ~ tracked in home/
HOME_ITEMS=(.zshrc .zshenv .p10k.zsh .gitconfig)

# Never copied in either direction: backups, runtime state, machine-local files.
# Anchored patterns are relative to ~/.config.
RSYNC_EXCLUDES=(
  --exclude='*.bak' --exclude='*.bak-*' --exclude='*.log'
  --exclude='.git/' --exclude='.claude/' --exclude='__pycache__/'
  --exclude='/hypr/wallpaper_effects/' --exclude='/hypr/.initial_startup_done'
  --exclude='/rofi/.current_wallpaper'
)

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> WARNING:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m==> ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# Print the entries of package list files without comments or blank lines.
read_list() {
  local f
  for f in "$@"; do
    [[ -f $f ]] && sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$f"
  done
  return 0
}

load_nvm() {
  export NVM_DIR="$HOME/.nvm"
  [[ -s $NVM_DIR/nvm.sh ]] || return 1
  set +u
  # shellcheck disable=SC1091
  source "$NVM_DIR/nvm.sh"
  set -u
}
