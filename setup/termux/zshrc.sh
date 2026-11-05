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

# The Obsidian vault lives in Android shared storage.
cdv() {
  cd -- /storage/emulated/0/Documents/my-vault
}

clv() (
  local vault_dir=/storage/emulated/0/Documents/my-vault
  mkdir -p -- "${vault_dir:h}" || return
  git clone --origin origin --branch main git@github.com:stryukovsky/my-vault.git "$vault_dir"
)

wv() (
  cdv || return
  git add -A || return
  if ! git diff --cached --quiet; then
    git commit -m "vault: update $(date '+%Y-%m-%d %H:%M:%S')" || return
  fi
  git push --force git@github.com:stryukovsky/my-vault.git HEAD:refs/heads/main
)

rv() (
  cdv || return
  git fetch git@github.com:stryukovsky/my-vault.git refs/heads/main || return
  git reset --hard FETCH_HEAD
)

update-termux() {
  pkg update && pkg upgrade || return
  [[ ! -f $ZSH/tools/upgrade.sh ]] || zsh "$ZSH/tools/upgrade.sh"
}

if [[ -o interactive ]]; then
  echo 'Vault: /storage/emulated/0/Documents/my-vault'
  echo '  clv  clone vault from GitHub'
  echo '  cdv  cd into vault'
  echo '  wv   commit local changes and overwrite remote (force-push)'
  echo '  rv   overwrite local tracked files and history from remote main'
fi
