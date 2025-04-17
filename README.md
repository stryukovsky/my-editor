# My Editor
## Prerequisites

### Install neovim  

https://github.com/neovim/neovim  

NOTE: make sure you installed copy-paste buffer adapter for your desktop environment on Linux systems.  

### Install gcc and make

This step mainly depends on platform you are running. Consider install these components using your system package manager.  

### Install ripgrep

https://github.com/BurntSushi/ripgrep

### Install rust

```shell
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Install nvm
https://github.com/nvm-sh/nvm

Use latest node version `nvm install LATEST_VERSION`  

Run 

```shell
npm i -g yarn tsx ts-node typescript
```

### Install golang
https://go.dev/dl/

Make sure `go` binary is available from your bash

### Install coursier
https://get-coursier.io/docs/cli-installation  

If needed, change permission to `cs` binary  

Install metals  
`cs install metals`  

### Install SDKMAN
`curl -s "https://get.sdkman.io" | bash`

Install Java version needed

`sdk install java YOUR_VERSION`

### Install pyenv

https://github.com/pyenv/pyenv

Install your python version

`pyenv install YOUR_VERSION`

### Install bpytop

https://github.com/aristocratos/bpytop  

## Setup:  

1) Install NvChad
2) Make sure it installs initial config
3) Remove `rm -rf ~/.config/nvim/`
4) Clone this `git clone https://github.com/stryukovsky/my-editor ~/.config/nvim/`
5) Run in nvim command `:MasonInstallAll`

Init mason dependencies:

```lua
vim.cmd("MasonInstall codelldb")
vim.cmd("MasonInstall css-lsp")
vim.cmd("MasonInstall delve")
vim.cmd("MasonInstall gopls")
vim.cmd("MasonInstall html-lsp")
vim.cmd("MasonInstall js-debug-adapter")
vim.cmd("MasonInstall json-lsp")
vim.cmd("MasonInstall lua-language-server")
vim.cmd("MasonInstall rust-analyzer")
vim.cmd("MasonInstall sqls")
vim.cmd("MasonInstall stylua")
vim.cmd("MasonInstall typescript-language-server")
vim.cmd("MasonInstall bash-language-server")
vim.cmd("MasonInstall solidity")
vim.cmd("MasonInstall solidity-ls")
vim.cmd("MasonInstall vscode-solidity-server")
vim.cmd("MasonInstall pyright")
```
