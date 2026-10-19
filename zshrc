# (ZSH) 'POWERLEVEL10K' THEME ---------------------------------------------------
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# ==============================================================================

alias n='nvim'
alias nz='nvim ~/.zshrc'
alias nn='nvim ~/.config/nvim/init.vim'
alias nh='nvim ~/.config/hypr'
alias sz='source ~/.zshrc'

alias lx='exa -lFagu --group-directories-first --icons'

alias claude="/home/evilnis/.claude/local/claude"

# git aliases
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gca='git commit --amend'
alias gco='git checkout'
alias gsw='git switch'
alias gswc='git switch -c'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --decorate --graph'
alias glo='git log --oneline --decorate --graph --all'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull'
alias gf='git fetch'
alias gfa='git fetch --all --prune'
alias gr='git restore'
alias grs='git restore --staged'
alias gstash='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gbr='git branch --show-current'



# START OF RELEVANT SYNTAX
# ******************************************************************************

# MANUALLY SET THE ENVIRONMENT LANGUAGE ----------------------------------------
# => Needed to make the 'BULLET TRAIN' git icons work correclty!
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8 # ==============================================================================


# MANUALLY SET THE 'PATH' ENVIRONMENT VARIABLES --------------------------------
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
# export MANPATH="/usr/local/man:$MANPATH"
# ==============================================================================


# NVM SETUP --------------------------------------------------------------------
# => This is needed on MacOS only because NVM was installed through homebrew.
# => On Linux / Windows WSL the if-statement should return 'false'.
if command -v brew >/dev/null 2>&1; then
  export NVM_DIR=~/.nvm
  source $(brew --prefix nvm)/nvm.sh
fi
# ==============================================================================


# (ZSH) HISTORY-SUBSTRING-SEARCH CUSTOMISATION ---------------------------------
setopt HIST_IGNORE_ALL_DUPS
# ==============================================================================


# ZGEN SETUP -------------------------------------------------------------------
# => Load the zgen script.
source "${HOME}/.zgen/zgen.zsh"

# Check if there's no init script.
if ! zgen saved; then
    echo "Creating a zgen save"

    zgen oh-my-zsh

    # plugins
    zgen oh-my-zsh plugins/git
    zgen oh-my-zsh plugins/ssh-agent
    zgen oh-my-zsh plugins/wd
    zgen load lukechilds/zsh-nvm
    # zgen oh-my-zsh plugins/npm
    # zgen oh-my-zsh plugins/docker
    # zgen oh-my-zsh plugins/docker-compose
    zgen load zsh-users/zsh-syntax-highlighting
    zgen load zsh-users/zsh-history-substring-search

    # completions
    zgen load zsh-users/zsh-completions src

    # theme
    zgen load romkatv/powerlevel10k powerlevel10k


    # save all to init script
    zgen save
fi

# => "zsh-history-substring-search" plugin
# => Key bindings (for UP and DOWN arrow keys).
zmodload zsh/terminfo
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
# ==============================================================================

# ******************************************************************************
# END OF RELEVANT SYNTAX
# ******************************************************************************

#Rust:
source $HOME/.cargo/env

# Golang:
export GOPATH=$HOME/Projects/go

# P10K To customize prompt, run `p10k configure` or edit ~/.p10k.zsh:
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#FZF:
source <(fzf --zsh)
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

#LVIM
export PATH=/home/evilnis/.local/bin:$PATH

#Zoxide
eval "$(zoxide init zsh)"

# pnpm
export PNPM_HOME="/home/evilnis/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "/home/evilnis/.bun/_bun" ] && source "/home/evilnis/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

fastfetch
