#!/usr/bin/env bash
# Run as your regular user, with or without sudo. Afterwards, use sudo nvim.
# Root shares this checkout, including its plugins and Mason installations.
set -euo pipefail

if (( $# != 0 )); then
  printf 'Usage: %s\n' "${0##*/}" >&2
  exit 2
fi

script_path=$(readlink -f -- "${BASH_SOURCE[0]}")
config_dir=$(dirname -- "$(dirname -- "$(dirname -- "$script_path")")")
if [[ ! -f $config_dir/init.lua ]]; then
  printf 'Neovim configuration not found: %s\n' "$config_dir" >&2
  exit 1
fi

if (( EUID != 0 )); then
  exec sudo -- bash "$script_path"
fi

root_home=$(getent passwd root | cut -d: -f6)
if [[ $root_home != /* || $root_home == / ]]; then
  printf 'Cannot determine root home directory.\n' >&2
  exit 1
fi
target="$root_home/.config/nvim"

if [[ -L $target && $(readlink -f -- "$target") == "$config_dir" ]]; then
  printf 'Root already uses %s\n' "$config_dir"
  exit 0
fi

mkdir -p -- "$root_home/.config"
if [[ -e $target || -L $target ]]; then
  backup_dir=$(mktemp -d -- "$root_home/.config/nvim.backup.XXXXXXXX")
  mv -- "$target" "$backup_dir/nvim"
  printf 'Previous root configuration saved to %s/nvim\n' "$backup_dir"
fi

ln -s -- "$config_dir" "$target"
printf 'Root now uses %s. Run: sudo nvim\n' "$config_dir"
