#!/usr/bin/env bash
set -euo pipefail
: "${PREFIX:?Run this script inside Termux}"
setup_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
mkdir -p -- "$HOME/.local/bin" "$HOME/.local/state/vault-sync"
cp -- "$setup_dir/vault-sync.sh" "$HOME/.local/bin/vault-sync"
chmod 700 "$HOME/.local/bin/vault-sync"
if [[ -n ${VAULT_DIR:-} || ! -f $HOME/.local/state/vault-sync/vault-path ]]; then
  printf '%s\n' "${VAULT_DIR:-/storage/emulated/0/Documents/my-vault}" > "$HOME/.local/state/vault-sync/vault-path"
fi

# Keep unrelated cron jobs; replace our marked job on repeated setup runs.
cron_file=$(mktemp)
trap 'rm -f -- "$cron_file" "$cron_file.error"' EXIT
if ! crontab -l > "$cron_file" 2> "$cron_file.error"; then
  if ! grep -qi 'no crontab' "$cron_file.error"; then
    cat "$cron_file.error" >&2
    rm -f -- "$cron_file.error"
    exit 1
  fi
  : > "$cron_file"
fi
rm -f -- "$cron_file.error"
sed -i '/# termux-vault-sync$/d' "$cron_file"
# Keep the installed job path independent of this checkout's location.
printf '*/3 * * * * %s/bin/bash "$HOME/.local/bin/vault-sync" >> "$HOME/.local/state/vault-sync/cron.log" 2>&1 # termux-vault-sync\n' "$PREFIX" >> "$cron_file"
crontab "$cron_file"

# This profile script starts runsvdir without needing another login shell.
source "$PREFIX/etc/profile.d/start-services.sh"
export SVDIR="$PREFIX/var/service"
# runsvdir starts asynchronously; allow its supervisor time to appear.
ready=false
for attempt in {1..10}; do
  if sv-enable crond; then
    ready=true
    break
  fi
  sleep 1
done
"$ready" || { echo 'crond did not start; reopen Termux and run sv-enable crond.' >&2; exit 1; }
sv status crond
termux-wake-lock
