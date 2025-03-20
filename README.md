# My Editor

Setup:  

1) Install NvChad
2) Make sure it installs initial config
3) Remove `rm -rf ~/.config/nvim/`
4) Clone this `https://github.com/stryukovsky/my-editor ~/.config/nvim/`
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
vim.cmd("MasonInstall nomicfoundation-solidity-language-server")
```
