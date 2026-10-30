#!/usr/bin/env bash
# Interactive Termux shell/editor setup and manual Obsidian vault commands.
set -euo pipefail

command -v pkg >/dev/null || { echo 'Run this script inside Termux.' >&2; exit 1; }
: "${PREFIX:?Termux PREFIX is not set}"
setup_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
vault_dir=/storage/emulated/0/Documents/my-vault

termux-setup-storage
printf '\nChoose a nearby package mirror or regional mirror group.\n'
termux-change-repo
pkg update -y
pkg install -y git openssh coreutils zsh neovim fzf tmux ranger htop

# Remove only the old vault job, preserving unrelated schedules and services.
if command -v crontab >/dev/null; then
  cron_file=$(mktemp)
  trap 'rm -f -- "$cron_file" "$cron_file.error" "$cron_file.new"' EXIT
  if crontab -l > "$cron_file" 2> "$cron_file.error"; then
    if grep -q '# termux-vault-sync$' "$cron_file"; then
      sed '/# termux-vault-sync$/d' "$cron_file" > "$cron_file.new"
      crontab "$cron_file.new"
      if ! grep -Eq '^[[:space:]]*[^#[:space:]]' "$cron_file.new"; then
        if command -v sv-disable >/dev/null; then
          SVDIR="$PREFIX/var/service" sv-disable crond || printf 'Could not stop the old crond service.\n' >&2
        fi
        if command -v termux-wake-unlock >/dev/null; then
          termux-wake-unlock
        fi
      fi
    fi
  elif ! grep -qi 'no crontab' "$cron_file.error"; then
    cat "$cron_file.error" >&2
    exit 1
  fi
  rm -f -- "$cron_file" "$cron_file.error" "$cron_file.new"
  trap - EXIT
fi
rm -f -- "$HOME/.local/bin/vault-sync"

git config --global user.email "strukovsky1@gmail.com"
git config --global user.name "Dmitry Stryukovsky"
if ! git config --global --get-all safe.directory | grep -Fxq "$vault_dir"; then
  git config --global --add safe.directory "$vault_dir"
fi
if [[ -e $vault_dir/.git ]]; then
  git -C "$vault_dir" config core.filemode false
fi

# Keep one backup of existing config files and make reruns harmless.
install_config() {
  local source_file=$1 target_file=$2
  mkdir -p -- "$(dirname -- "$target_file")"
  if cmp -s -- "$source_file" "$target_file"; then
    return
  fi
  if [[ -e $target_file && ! -e $target_file.before-termux-setup ]]; then
    cp -pL -- "$target_file" "$target_file.before-termux-setup"
  fi
  cp --remove-destination -- "$source_file" "$target_file"
}
install_config "$setup_dir/zshrc.sh" "$HOME/.zshrc"
install_config "$setup_dir/colors.properties" "$HOME/.termux/colors.properties"
install_config "$setup_dir/tmux.conf" "$HOME/.tmux.conf"
install_config "$setup_dir/ranger/rc.conf" "$HOME/.config/ranger/rc.conf"
install_config "$setup_dir/ranger/rifle.conf" "$HOME/.config/ranger/rifle.conf"
install_config "$setup_dir/../fedora/ranger/colorschemes/wheat.py" "$HOME/.config/ranger/colorschemes/wheat.py"
chsh -s zsh
if command -v termux-reload-settings >/dev/null; then
  termux-reload-settings
fi

mkdir -p -- "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
key_file="$HOME/.ssh/id_ed25519"
if [[ ! -f $key_file ]]; then
  ssh-keygen -t ed25519 -C 'strukovsky1@gmail.com' -f "$key_file"
elif [[ ! -f $key_file.pub ]]; then
  ssh-keygen -y -f "$key_file" > "$key_file.pub"
fi
printf '\nSetup complete. Start zsh, then use clv, cdv, wv (overwrite remote), or rv (stash/fetch/pop).\n'
printf '\nFinally, add this public key to GitHub: https://github.com/settings/ssh/new\n'
cat -- "$key_file.pub"
