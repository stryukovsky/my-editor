# My Editor

Install wezterm: 

https://wezterm.org/index.html

Clone this repository:

```sh 
git clone https://github.com/stryukovsky/my-editor ~/.config/nvim/
```

Install font from `fonts/` directory of this repo to your system  

In `~/.config/nvim/` run following:  

```sh
sudo bash setup.fedora.sh
bash setup.commons.sh
cp wezterm.lua ~/.wezterm.lua
cp zsh.fedora.sh ~/.zshrc
```

Open neovim and run command
```
MasonInstall codelldb css-lsp  delve gopls html-lsp js-debug-adapter json-lsp lua-language-server rust-analyzer sqls stylua typescript-language-server bash-language-server solidity solidity-ls vscode-solidity-server pyright goimports prettier clangd
```



# Manual Installation (instead of setup.fedora.sh)

## Prerequisites

### Install neovim  

https://github.com/neovim/neovim  

NOTE: make sure you installed copy-paste buffer adapter for your desktop environment on Linux systems.  

### Install gcc, g++ and make

This step mainly depends on platform you are running. Consider install these components using your system package manager.  

### Install ripgrep

https://github.com/BurntSushi/ripgrep

### Install bpytop

https://github.com/aristocratos/bpytop  

