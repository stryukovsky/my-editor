export PATH="$HOME/bin:$HOME/.local/bin:$HOME/go/bin:$PATH"
export EDITOR=nvim
export VISUAL=nvim
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="philips"
zstyle ':omz:update' mode disabled
COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
plugins=(git golang pip python rust zsh-interactive-cd)
[[ ! -f $ZSH/oh-my-zsh.sh ]] || source "$ZSH/oh-my-zsh.sh"

if command -v fzf >/dev/null; then
  source <(fzf --zsh)
fi
export FZF_DEFAULT_OPTS='--height 40% --layout reverse --border top'
alias top=htop
alias ff=ranger
alias mc=ranger
alias o=termux-open
alias vim=nvim
alias activ='source .venv/bin/activate'

pullvault() {
  local vault_dir=${VAULT_DIR:-/storage/emulated/0/Documents/my-vault}
  if [[ ! -d $vault_dir/.git ]]; then
    mkdir -p -- "${vault_dir:h}" || return
    git clone git@github.com:stryukovsky/my-vault.git "$vault_dir" || return
  fi
  git -C "$vault_dir" pull --ff-only
}

pushvault() {
  # Share cron's sync sequence, saved vault path, lock, and conflict handling.
  VAULT_DIR="${VAULT_DIR:-}" bash "$HOME/.local/bin/vault-sync"
}
alias pv=pushvault

update-termux() {
  pkg update && pkg upgrade || return
  [[ ! -f $ZSH/tools/upgrade.sh ]] || zsh "$ZSH/tools/upgrade.sh"
}
