#!/usr/bin/env bash
# Move the big, non-git parts of the desktop between PCs (USB stick, external
# drive, or a mounted network share):
#
#   scripts/extras.sh export /run/media/$USER/USB    # on the old PC
#   scripts/extras.sh import /run/media/$USER/USB    # on the new PC
#
# Files land in <dir>/dotfiles-extras/ with their paths relative to ~.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ~1.6 GB on the old PC: wallpapers used by the wallpaper picker and wallust,
# cursor/icon themes and GTK themes set by ~/.config/hypr/initial-boot.sh.
EXTRAS=(Pictures/wallpapers .icons .themes)

[[ $# -eq 2 ]] || die "usage: $0 export|import <dir>"
dest="$2/dotfiles-extras"

case "$1" in
  export)
    mkdir -p "$dest"
    for item in "${EXTRAS[@]}"; do
      if [[ -e $HOME/$item ]]; then
        info "Exporting ~/$item"
        rsync -aR --info=progress2 "$HOME/./$item" "$dest/"
      fi
    done
    ;;
  import)
    [[ -d $dest ]] || die "$dest not found"
    info "Importing $dest into ~"
    rsync -a --info=progress2 "$dest/" "$HOME/"
    ;;
  *) die "usage: $0 export|import <dir>" ;;
esac
info "Extras done."
