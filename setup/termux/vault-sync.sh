#!/usr/bin/env bash
# Stash -> pull -> pop -> stage/commit -> push, stopping on any failure.
set -euo pipefail
: "${PREFIX:?Run this script inside Termux}"
export PATH="$PREFIX/bin:$HOME/.local/bin:$PATH"
state_dir="$HOME/.local/state/vault-sync"
mkdir -p -- "$state_dir"
vault_dir=${VAULT_DIR:-/storage/emulated/0/Documents/my-vault}
if [[ -z ${VAULT_DIR:-} && -f $state_dir/vault-path ]]; then
  vault_dir=$(cat -- "$state_dir/vault-path")
fi
exec 9>"$state_dir/lock"
flock -n 9 || exit 0
# Cron cannot answer SSH prompts. Set up the key and known_hosts interactively.
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=20 -o StrictHostKeyChecking=yes'
export GIT_MERGE_AUTOEDIT=no
if [[ ! -d $vault_dir/.git ]]; then
  printf 'Vault checkout missing: %s. Clone it interactively first.\n' "$vault_dir" >&2
  exit 1
fi
cd -- "$vault_dir"

# Never turn an unresolved conflict or an interrupted operation into a sync commit.
for operation in MERGE_HEAD rebase-merge rebase-apply CHERRY_PICK_HEAD REVERT_HEAD; do
  if [[ -e $(git rev-parse --git-path "$operation") ]]; then
    printf 'Resolve the pending Git operation (%s) before syncing.\n' "$operation" >&2
    exit 1
  fi
done
if [[ -n $(git ls-files --unmerged) ]]; then
  echo 'Resolve unmerged vault files before syncing.' >&2
  exit 1
fi
# A failed pull/pop keeps our stash. Do not bury it under another automatic run.
if git stash list --format='%gs' | grep -q ': termux-vault-sync$'; then
  echo 'A previous sync stash needs recovery. Inspect git stash list, restore it, and resolve conflicts before syncing again.' >&2
  exit 1
fi

stash_id=''
changes=$(git status --porcelain)
if [[ -n $changes ]]; then
  git stash push --include-untracked -m 'termux-vault-sync'
  stash_id=$(git rev-parse refs/stash)
fi
# Merge diverged committed histories, without an interactive editor or rebase.
# On failure, leave the sync stash intact for manual recovery.
timeout 120 git pull --no-rebase --no-edit
if [[ -n $stash_id ]]; then
  if [[ $(git rev-parse refs/stash) != "$stash_id" ]]; then
    echo 'Stash changed during sync; restore the sync stash manually.' >&2
    exit 1
  fi
  git stash pop
fi
git add -A
if ! git diff --cached --quiet; then
  git commit -m 'sync'
fi
# Push even with no new changes: a previous attempt may have committed but failed to push.
timeout 120 git push
