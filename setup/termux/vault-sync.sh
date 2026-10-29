#!/usr/bin/env bash
# Pull only: cron never commits, stashes, merges, or pushes local edits.
set -euo pipefail
: "${PREFIX:?Run this script inside Termux}"
export PATH="$PREFIX/bin:$HOME/.local/bin:$PATH"
vault_dir=${VAULT_DIR:-/storage/emulated/0/Documents/my-vault}
state_dir="$HOME/.local/state/vault-sync"
mkdir -p -- "$state_dir"
exec 9>"$state_dir/lock"
flock -n 9 || exit 0
# Cron cannot answer SSH prompts. Set up the key and known_hosts interactively.
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=20 -o StrictHostKeyChecking=yes'
if [[ ! -d $vault_dir/.git ]]; then
  printf 'Vault checkout missing: %s. Run pullvault interactively first.\n' "$vault_dir" >&2
  exit 1
fi
if [[ -n $(git -C "$vault_dir" status --porcelain) ]]; then
  printf 'Vault has local changes; skipping automatic pull: %s\n' "$vault_dir" >&2
  exit 0
fi
timeout 120 git -C "$vault_dir" pull --ff-only
