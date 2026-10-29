#!/usr/bin/env bash
# Set up a fresh Arch/EndeavourOS install from this repo.
#
#   ./install.sh              # everything, asking before each paru transaction
#   ./install.sh -y           # everything, no paru prompts / AUR review
#   ./install.sh configs dev  # only some steps (packages, configs, dev)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib.sh"

((EUID != 0)) || die "run this as your normal user, not root (it uses sudo itself)"
command -v pacman >/dev/null || die "this setup expects an Arch-based system (pacman)"

yes=()
steps=()
for arg in "$@"; do
  case "$arg" in
    -y) yes=(-y) ;;
    packages|configs|dev) steps+=("$arg") ;;
    *) die "unknown argument '$arg' (expected -y, packages, configs, dev)" ;;
  esac
done
# configs before dev: rustup must see the repo's .zshenv so it doesn't add its own line
((${#steps[@]})) || steps=(packages configs dev)

for step in "${steps[@]}"; do
  info "---- $step ----"
  bash "$DOTFILES/scripts/$step.sh" "${yes[@]}"
done

cat <<'EOF'

All done. Next:
  - log out and pick the Hyprland session (or reboot)
  - first zsh start downloads the zgen plugins + powerlevel10k (takes a few seconds)
  - wallpapers/icons/themes: scripts/extras.sh import <usb-dir>
  - check monitor names in ~/.config/hypr/hyprland.lua (see README)
EOF
