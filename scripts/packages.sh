#!/usr/bin/env bash
# Install paru, every package from packages/*.txt, enable services and make zsh
# the login shell. Safe to re-run: already installed packages are skipped.
#
#   scripts/packages.sh        # asks before each paru transaction
#   scripts/packages.sh -y     # --noconfirm, and skip AUR PKGBUILD review
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

((EUID != 0)) || die "run this as your normal user, not root (it uses sudo itself)"

NOCONFIRM=()
AUR_FLAGS=()
[[ ${1:-} == -y ]] && NOCONFIRM=(--noconfirm) && AUR_FLAGS=(--skipreview)
PARU_FLAGS=(--needed "${NOCONFIRM[@]}")

install_paru() {
  command -v paru >/dev/null && return
  info "Installing paru"
  if pacman -Si paru &>/dev/null; then
    # EndeavourOS (and chaotic-aur) ship paru in a repo
    sudo pacman -S --needed "${NOCONFIRM[@]}" paru
  else
    sudo pacman -S --needed "${NOCONFIRM[@]}" base-devel git
    local tmp
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
    (cd "$tmp/paru-bin" && makepkg -si "${NOCONFIRM[@]}")
    rm -rf "$tmp"
  fi
}

check_multilib() {
  if ! pacman -Sl multilib &>/dev/null; then
    warn "[multilib] is not enabled in /etc/pacman.conf - steam and lib32-* packages will be skipped."
    warn "Uncomment the [multilib] section, run 'sudo pacman -Sy' and re-run this script to get them."
  fi
}

install_packages() {
  # Full upgrade first: installing on top of a bare -Sy risks a partial upgrade.
  info "Upgrading the system"
  sudo pacman -Syu "${NOCONFIRM[@]}"

  local lists=("$PKG_DIR/aur.txt" "$PKG_DIR/extra.txt")
  if lspci 2>/dev/null | grep -iE 'vga|3d|display' | grep -qE 'AMD|ATI|Radeon'; then
    info "AMD GPU detected, including packages/amd.txt"
    lists+=("$PKG_DIR/amd.txt")
  fi

  local -a in_repos missing repo_pkgs aur_pkgs
  mapfile -t in_repos < <(pacman -Slq | sort -u)

  # repo.txt: everything must come from the repos; names that are gone (renamed,
  # or EndeavourOS-only on plain Arch) are reported and skipped.
  mapfile -t repo_pkgs < <(comm -12 <(read_list "$PKG_DIR/repo.txt" | sort -u) <(printf '%s\n' "${in_repos[@]}"))
  mapfile -t missing   < <(comm -23 <(read_list "$PKG_DIR/repo.txt" | sort -u) <(printf '%s\n' "${in_repos[@]}"))
  # Other lists: repo if available, AUR otherwise.
  mapfile -t -O "${#repo_pkgs[@]}" repo_pkgs < <(comm -12 <(read_list "${lists[@]}" | sort -u) <(printf '%s\n' "${in_repos[@]}"))
  mapfile -t aur_pkgs  < <(comm -23 <(read_list "${lists[@]}" | sort -u) <(printf '%s\n' "${in_repos[@]}"))

  # Drop anything already satisfied, including by a package that provides it
  # (e.g. iptables-nft provides iptables), so paru doesn't try to swap them.
  if ((${#repo_pkgs[@]})); then mapfile -t repo_pkgs < <(pacman -T "${repo_pkgs[@]}" || true); fi
  if ((${#aur_pkgs[@]})); then mapfile -t aur_pkgs < <(pacman -T "${aur_pkgs[@]}" || true); fi

  if ((${#missing[@]})); then warn "Not in any enabled repo, skipped: ${missing[*]}"; fi

  if ((${#repo_pkgs[@]})); then
    info "Installing ${#repo_pkgs[@]} repo packages"
    paru -S "${PARU_FLAGS[@]}" "${repo_pkgs[@]}"
  fi

  if ((${#aur_pkgs[@]})); then
    info "Installing ${#aur_pkgs[@]} AUR packages: ${aur_pkgs[*]}"
    if ! paru -S "${PARU_FLAGS[@]}" "${AUR_FLAGS[@]}" "${aur_pkgs[@]}"; then
      warn "AUR batch failed, retrying one package at a time"
      local pkg failed=()
      for pkg in "${aur_pkgs[@]}"; do
        paru -S "${PARU_FLAGS[@]}" "${AUR_FLAGS[@]}" "$pkg" || failed+=("$pkg")
      done
      if ((${#failed[@]})); then warn "AUR packages that failed: ${failed[*]}"; fi
    fi
  fi
}

enable_services() {
  info "Enabling services"
  local svc
  while IFS= read -r svc; do
    if systemctl cat "$svc" &>/dev/null; then
      sudo systemctl enable --now "$svc" || warn "could not enable $svc"
    else
      warn "$svc is not installed, skipping"
    fi
  done < <(read_list "$PKG_DIR/services.txt")
}

set_shell() {
  local zsh
  zsh=$(command -v zsh) || return 0
  if [[ $(getent passwd "$USER" | cut -d: -f7) != "$zsh" ]]; then
    info "Changing login shell to $zsh"
    chsh -s "$zsh"
  fi
}

install_paru
check_multilib
install_packages
enable_services
set_shell
info "Packages done."
