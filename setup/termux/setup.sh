#!/usr/bin/env bash
# Minimal setup for the vault sync cron job.
set -euo pipefail

command -v pkg >/dev/null || { echo 'Run this script inside Termux.' >&2; exit 1; }
: "${PREFIX:?Termux PREFIX is not set}"
setup_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
vault_dir=${VAULT_DIR:-/storage/emulated/0/Documents/my-vault}

termux-setup-storage
pkg update -y
pkg install -y git openssh coreutils util-linux cronie termux-services

git config --global user.email "strukovsky1@gmail.com"
git config --global user.name "Dmitry Stryukovsky"
if ! git config --global --get-all safe.directory | grep -Fxq "$vault_dir"; then
  git config --global --add safe.directory "$vault_dir"
fi

bash "$setup_dir/install-cron.sh"
printf '\nVault sync cron installed (every 3 minutes). See setup/termux/README.md for SSH and initial clone setup.\n'
