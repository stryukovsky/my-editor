#!/usr/bin/env bash
set -euo pipefail

command -v pkg >/dev/null || { echo 'Run this script inside Termux.' >&2; exit 1; }
: "${PREFIX:?Termux PREFIX is not set}"
setup_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$setup_dir/../.." && pwd)

termux-setup-storage
pkg update -y
pkg upgrade -y
pkg install -y git openssh curl neovim clang zsh ripgrep fzf fd tmux ranger \
  htop make cmake ninja pkg-config python nodejs-lts golang rust tree-sitter \
  atool zip unzip jq util-linux cronie termux-services

# Fedora extras vary by Termux architecture/repository. Query this device's
# current package metadata instead of assuming Fedora names exist here.
extras=()
for package in pandoc imagemagick lldb lcov postgresql maven; do
  if apt-cache show "$package" >/dev/null 2>&1; then
    extras+=("$package")
  else
    printf 'Skipping unavailable optional package: %s\n' "$package"
  fi
done
((${#extras[@]} == 0)) || pkg install -y "${extras[@]}"

git config --global user.email "strukovsky1@gmail.com"
git config --global user.name "Dmitry Stryukovsky"
git config --global init.defaultBranch main
vault_dir=/storage/emulated/0/Documents/my-vault
if ! git config --global --get-all safe.directory | grep -Fxq "$vault_dir"; then
  git config --global --add safe.directory "$vault_dir"
fi

if [[ ! -d $HOME/.oh-my-zsh ]]; then
  installer=$(mktemp)
  trap 'rm -f -- "$installer"' EXIT
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$installer"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$installer"
fi

# Back up existing personal configs once before installing managed copies.
install_config() {
  local source=$1 target=$2
  mkdir -p -- "$(dirname -- "$target")"
  if [[ -e $target && ! -e $target.before-termux-setup ]]; then
    cp -p -- "$target" "$target.before-termux-setup"
  fi
  cp -- "$source" "$target"
}
install_config "$setup_dir/zshrc.sh" "$HOME/.zshrc"
install_config "$setup_dir/tmux.conf" "$HOME/.tmux.conf"
install_config "$setup_dir/ranger/rc.conf" "$HOME/.config/ranger/rc.conf"
install_config "$setup_dir/ranger/rifle.conf" "$HOME/.config/ranger/rifle.conf"
install_config "$repo_dir/setup/fedora/ranger/colorschemes/wheat.py" "$HOME/.config/ranger/colorschemes/wheat.py"
install_config "$repo_dir/fonts/AdwaitaMono/AdwaitaMonoNerdFont-Regular.ttf" "$HOME/.termux/font.ttf"
install_config "$setup_dir/colors.properties" "$HOME/.termux/colors.properties"
# Preserve unrelated Termux settings and replace only our extra-key layout.
properties="$HOME/.termux/termux.properties"
touch "$properties"
sed -i '/^extra-keys[[:space:]]*=/d' "$properties"
cat >> "$properties" <<'KEYS'
extra-keys = [['ESC','CTRL','ALT','TAB','LEFT','DOWN','UP','RIGHT']]
KEYS
termux-reload-settings
chsh -s zsh
bash "$setup_dir/install-cron.sh"
printf '\nSetup complete. Open a new Termux shell. See setup/termux/README.md for vault SSH and Android background settings.\n'
