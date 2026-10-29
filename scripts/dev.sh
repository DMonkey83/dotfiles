#!/usr/bin/env bash
# Developer toolchains that live in $HOME rather than in pacman:
# rustup + cargo tools, zgen, nvm + Node + global npm packages, bun,
# Claude Code, and the LazyVim plugins. Safe to re-run.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

install_rust() {
  if ! command -v rustup >/dev/null && [[ ! -x $HOME/.cargo/bin/rustup ]]; then
    info "Installing rustup (stable toolchain)"
    # .zshenv from this repo already sources ~/.cargo/env, rustup won't add it twice
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --default-toolchain stable --profile default
  fi
  # shellcheck disable=SC1091
  if [[ -f $HOME/.cargo/env ]]; then source "$HOME/.cargo/env"; else export PATH="$HOME/.cargo/bin:$PATH"; fi
  rustup default stable >/dev/null

  info "Installing cargo tools from packages/cargo.txt"
  local line failed=()
  while IFS= read -r line; do
    if [[ $line == --path* && ! -d ${line#--path } ]]; then
      warn "skipping '$line': directory not found (mount the drive and re-run)"
      continue
    fi
    # shellcheck disable=SC2086 # each line is a set of `cargo install` arguments
    cargo install --locked $line || failed+=("$line")
  done < <(read_list "$PKG_DIR/cargo.txt")
  if ((${#failed[@]})); then warn "cargo installs that failed: ${failed[*]}"; fi
}

install_zgen() {
  if [[ ! -d $HOME/.zgen ]]; then
    info "Installing zgen (zsh plugins + powerlevel10k load on the first zsh start)"
    git clone https://github.com/tarjoilija/zgen.git "$HOME/.zgen"
  fi
}

install_node() {
  if [[ ! -s $HOME/.nvm/nvm.sh ]]; then
    info "Installing nvm"
    git clone https://github.com/nvm-sh/nvm.git "$HOME/.nvm"
    git -C "$HOME/.nvm" checkout -q "$(git -C "$HOME/.nvm" describe --abbrev=0 --tags --match 'v[0-9]*' "$(git -C "$HOME/.nvm" rev-list --tags --max-count=1)")"
  fi
  load_nvm

  local versions
  mapfile -t versions < <(read_list "$PKG_DIR/node.txt")
  ((${#versions[@]})) || versions=('lts/*')

  # nvm is not written for `set -eu`
  set +eu
  local v
  for v in "${versions[@]}"; do
    info "Installing Node $v"
    nvm install "$v" || warn "nvm install $v failed"
  done
  nvm alias default "${versions[0]}"
  nvm use default >/dev/null

  local pkgs
  mapfile -t pkgs < <(read_list "$PKG_DIR/npm.txt")
  if ((${#pkgs[@]})); then
    info "Installing global npm packages: ${pkgs[*]}"
    npm install -g "${pkgs[@]}" || warn "some global npm packages failed"
  fi
  set -eu
}

install_bun() {
  if [[ -x $HOME/.bun/bin/bun ]]; then return; fi
  info "Installing bun"
  # SHELL=sh stops the installer from appending to .zshrc (the repo version already has the lines)
  curl -fsSL https://bun.sh/install | SHELL=/bin/sh bash
}

install_claude() {
  if command -v claude >/dev/null || [[ -x $HOME/.local/bin/claude ]]; then return; fi
  info "Installing Claude Code (native installer, ends up in ~/.local/bin)"
  curl -fsSL https://claude.ai/install.sh | bash
}

install_nvim_plugins() {
  command -v nvim >/dev/null || return 0
  info "Installing LazyVim plugins at the versions pinned in lazy-lock.json"
  nvim --headless "+Lazy! restore" +qa || warn "LazyVim plugin restore failed, it will retry on the first nvim start"
}

install_rust
install_zgen
install_node
install_bun || warn "bun install failed"
install_claude || warn "Claude Code install failed"
install_nvim_plugins
info "Dev tools done."
