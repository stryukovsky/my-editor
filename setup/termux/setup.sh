termux-setup-storage
pkg install git neovim clang zsh ripgrep

git config --global --add safe.directory /storage/emulated/0/Documents/my-vault
git config --global user.email "strukovsky1@gmail.com"
git config --global user.name "Dmitry Stryukovsky"

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
