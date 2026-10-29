#!/usr/bin/env bash
# Copy the configs from the repo into ~ and ~/.config.
# Files that get overwritten are saved under ~/.dotfiles-backup/<timestamp>/ first.
# Existing files that are not in the repo are left alone.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

info "Copying config/ into ~/.config (backups in $BACKUP)"
mkdir -p "$HOME/.config"
for item in "${CONFIG_ITEMS[@]}"; do
  [[ -e $DOTFILES/config/$item ]] || continue
  rsync -a --backup --backup-dir="$BACKUP/.config" "${RSYNC_EXCLUDES[@]}" \
    "$DOTFILES/config/$item" "$HOME/.config/"
done

info "Copying home/ into ~"
for item in "${HOME_ITEMS[@]}"; do
  [[ -e $DOTFILES/home/$item ]] || continue
  rsync -a --backup --backup-dir="$BACKUP" "$DOTFILES/home/$item" "$HOME/"
done

if [[ -d $BACKUP ]]; then
  info "Overwritten files were backed up to $BACKUP"
fi
info "Configs done."
