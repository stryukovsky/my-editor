xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update
brew install fzf go bpytop pyenv openssl readline sqlite3 xz zlib tcl-tk@8 libb2 neovim make ripgrep postgresql@16 coursier/formulas/coursier tmux lazygit
cs setup
pyenv install 3.12
pyenv global 3.12
