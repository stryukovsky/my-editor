#!/bin/sh
# Write container or service logs to a file and copy an agent prompt plus that path.
set -eu

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/lazydocker/logs"
mkdir -p "$state_dir"

sanitize() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
}

write_file() {
  stem=$1
  shift
  file="$state_dir/$(sanitize "$stem").log"
  tmp="$file.tmp"
  if ! "$@" >"$tmp" 2>&1; then
    status=$?
  else
    status=0
  fi
  {
    printf '# %s\n' "$stem"
    printf '# %s\n' "$*"
    printf '# %s\n\n' "$(date -Is)"
    cat "$tmp"
  } >"$file"
  rm -f "$tmp"
  if [ "$status" -ne 0 ] && [ ! -s "$file" ]; then
    printf 'yank-logs: log command failed\n' >&2
    exit "$status"
  fi
  printf 'whats going on here\n%s\n' "$file" | gpaste-client
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a lazydocker "Log path copied" "$file"
  fi
}

if [ "${1:-}" = "--all-containers" ]; then
  write_file all-containers sh -c '
    docker ps -a --format "{{.ID}} {{.Names}}" | while read -r id name; do
      printf "\n===== %s (%s) =====\n" "$name" "$id"
      docker logs --timestamps --tail 400 "$id" 2>&1 || true
    done
  '
  exit 0
fi

stem=${1:?usage: yank-logs.sh <name> -- <command>}
shift
if [ "${1:-}" != "--" ]; then
  printf 'yank-logs: expected -- before the log command\n' >&2
  exit 1
fi
shift
if [ "$#" -eq 0 ]; then
  printf 'yank-logs: missing log command\n' >&2
  exit 1
fi

write_file "$stem" "$@"
