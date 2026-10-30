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
  git clone git@github.com:stryukovsky/my-vault.git "$vault_dir" || return
  git -C "$vault_dir" config core.filemode false
)

_vault_ready() {
  local operation
  [[ -e .git ]] || { print -u2 'Vault checkout missing; run clv first.'; return 1; }
  for operation in MERGE_HEAD rebase-merge rebase-apply CHERRY_PICK_HEAD REVERT_HEAD; do
    if [[ -e $(git rev-parse --git-path "$operation") ]]; then
      print -u2 "Resolve the pending Git operation ($operation) first."
      return 1
    fi
  done
  [[ -z $(git ls-files --unmerged) ]] || { print -u2 'Resolve unmerged vault files first.'; return 1; }
}

# Write vault: local files/history replace the tracked remote branch.
wv() (
  cdv || return
  _vault_ready || return
  local branch remote target
  branch=$(git symbolic-ref --quiet --short HEAD) || return
  remote=$(git config --get "branch.$branch.remote") || remote=origin
  target=$(git config --get "branch.$branch.merge") || target="refs/heads/$branch"
  git add -A || return
  if ! git diff --cached --quiet; then
    git commit -m "vault: update $(date '+%Y-%m-%d %H:%M:%S')" || return
  fi
  git push --force -- "$remote" "HEAD:$target"
)

# Read vault: keep local edits in a stash while fast-forwarding to the remote.
rv() (
  cdv || return
  _vault_ready || return
  local branch remote target changes stash_id=''
  branch=$(git symbolic-ref --quiet --short HEAD) || return
  remote=$(git config --get "branch.$branch.remote") || remote=origin
  target=$(git config --get "branch.$branch.merge") || target="refs/heads/$branch"
  changes=$(git status --porcelain) || return
  if [[ -n $changes ]]; then
    git stash push --include-untracked -m termux-vault-read || return
    stash_id=$(git rev-parse refs/stash) || return
  fi
  if ! git fetch -- "$remote" "$target" || ! git merge --ff-only FETCH_HEAD; then
    [[ -z $stash_id ]] || print -u2 "Local edits are preserved in stash $stash_id (termux-vault-read)."
    return 1
  fi
  if [[ -n $stash_id ]]; then
    if [[ $(git rev-parse refs/stash) != "$stash_id" ]]; then
      print -u2 "Stash changed; restore $stash_id manually."
      return 1
    fi
    git stash pop
  fi
)

# Keep the old long names working for existing shell habits.
pushvault() { wv "$@"; }
pullvault() { rv "$@"; }
alias pv=wv

update-termux() {
  pkg update && pkg upgrade || return
  [[ ! -f $ZSH/tools/upgrade.sh ]] || zsh "$ZSH/tools/upgrade.sh"
}

if [[ -o interactive ]]; then
  echo 'Vault: /storage/emulated/0/Documents/my-vault'
  echo '  clv  clone vault from GitHub'
  echo '  cdv  cd into vault'
  echo '  wv   commit local changes and overwrite remote (force-push)'
  echo '  rv   stash local edits, fetch/fast-forward remote, pop stash'
fi
