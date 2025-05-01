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

# Cuda NVIDIA
Avante needs llama to be launched: 

```sh
curl -fsSL https://ollama.com/install.sh | sh
```

You need to install NVIDIA drivers:  

https://rpmfusion.org/Howto/NVIDIA


```sh
sudo dnf update -y 
sudo dnf install akmod-nvidia 
sudo dnf install xorg-x11-drv-nvidia-cuda 
```


### Known problems with NVidia video drivers:  

Out of range

It seems that there is a problem with HDMI deepcolor which is enabled by default in NVIDIA drivers. Idk if it’s related to higher refresh rates or HDMI versions because changing from 2.0 to 1.4 also solves this (but with the 120hz limitation of 1.4).

To disable deep color you can add “nvidia-modeset.hdmi_deepcolor=0” to /etc/default/grub parameters like this GRUB_CMDLINE_LINUX="<other-parameters> nvidia-modeset.hdmi_deepcolor=0" and then rebuid grub config using grub2-mkconfig.

Also I don’t know if this can create issues to certain monitors or graphic cards but this fixed it for me.

# Wireguard install
First try in UI Networks add VPN from file. Note file shall be named as `somestring.conf`.  

If failure:

```sh
wg-quick up  ~/Documents/vpn.conf
```

Repeat again interactions with UI.  

## Manual Installation (instead of usage setup.fedora.sh)

### Install neovim  

https://github.com/neovim/neovim  

NOTE: make sure you installed copy-paste buffer adapter for your desktop environment on Linux systems.  

### Install gcc, g++ and make

This step mainly depends on platform you are running. Consider install these components using your system package manager.  

### Install ripgrep

https://github.com/BurntSushi/ripgrep

### Install bpytop

https://github.com/aristocratos/bpytop  

### Install golang 

https://go.dev/

### Install pyenv build dependencies

https://github.com/pyenv/pyenv/wiki#suggested-build-environment
