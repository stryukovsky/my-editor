# My Editor

Clone this repository:

```sh 
git clone https://github.com/stryukovsky/my-editor ~/.config/nvim/
```


In `~/.config/nvim/` you need to run setup scripts:  

# Ready instructions on platforms

## Basics
Install basics with script on every platform  

### MacOS:  
Install alacritty:  
https://alacritty.org/  
Install font from `fonts/` directory of this repo to your system.   

Execute every line separately!!!  

```sh
bash setup/macos/setup.sh 
bash setup/commons.sh
cp setup/macos/alacritty.toml ~/.alacritty.toml
cp setup/tmux.conf ~/.tmux.conf
cp setup/tmux/my-theme.sh ~/.tmux/plugins/tmux-powerline/themes/
cp setup/macos/zsh.sh ~/.zshrc
bash setup/finalize.sh
```

### Fedora / Asahi Fedora linux:  

Firstly make sure system is up-to-date:  

```
sudo dnf upgrade -y
```

Enable [rpm fusion](https://docs.fedoraproject.org/en-US/quick-docs/rpmfusion-setup/) packages.  


Execute every line separately!!!  

```sh
sudo bash setup/fedora/setup.sh 
bash setup/fedora/pyenv.sh
bash setup/commons.sh
bash setup/fedora/gnome.sh
cp setup/fedora/alacritty.toml ~/.alacritty.toml
cp setup/tmux.conf ~/.tmux.conf
cp setup/tmux/my-theme.sh ~/.tmux/plugins/tmux-powerline/themes/
cp setup/fedora/zsh.sh ~/.zshrc
bash setup/finalize.sh
```

Install plugins in tmux (`<prefix>I`).  

For asahi linux also install `light` package

**Note**: read all stuff related to fedora below. Especially drivers and root password

## Setup mason plugins
After installation of basics, open neovim and run command
```
MasonInstall codelldb css-lsp  delve gopls html-lsp js-debug-adapter lua-language-server rust-analyzer sqls stylua typescript-language-server bash-language-server basedpyright goimports prettier clangd nomicfoundation-solidity-language-server black gofumpt vscode-solidity-server
```

Install TS parsers:  

```
TSInstall all
```

Install kulala-ls:  

```
npm install -g @mistweaverco/kulala-ls
```

# Other Fedora stuff

Note: NVIDIA may not work until secure boot is not configured properly.  
Note: [RPM Fusion](https://rpmfusion.org/Howto)

## Gnome look

Install plugins

- https://extensions.gnome.org/extension/19/user-themes/
- https://extensions.gnome.org/extension/7065/tiling-shell/
- https://extensions.gnome.org/extension/1460/vitals/
- https://extensions.gnome.org/extension/307/dash-to-dock/

Install orchis theme

https://github.com/vinceliuice/Orchis-theme

## Cuda NVIDIA & ollama 
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


### Known problems with NVidia drivers:  

Out of range

It seems that there is a problem with HDMI deepcolor which is enabled by default in NVIDIA drivers. Idk if it’s related to higher refresh rates or HDMI versions because changing from 2.0 to 1.4 also solves this (but with the 120hz limitation of 1.4).

To disable deep color you can add “nvidia-modeset.hdmi_deepcolor=0” to /etc/default/grub parameters like this GRUB_CMDLINE_LINUX="<other-parameters> nvidia-modeset.hdmi_deepcolor=0" and then rebuid grub config using grub2-mkconfig.

Also I don’t know if this can create issues to certain monitors or graphic cards but this fixed it for me.

## Wireguard install
First try in UI Networks add VPN from file. Note file shall be named as `somestring.conf`.  

If failure:

```sh
wg-quick up  ~/Documents/vpn.conf
```

Or `sudo nmcli connection import type wireguard file vpn.conf`

Repeat again interactions with UI.  

## Fedora root password set

Important stuff  

```sh
sudo passwd root
```

And then reboot  

# Manual Installation (instead of usage of ready basics setup instructions)

## Links 

https://github.com/neovim/neovim   
https://alacritty.org/  
https://github.com/tmux/tmux  

NOTE: make sure you installed copy-paste buffer adapter for your desktop environment on Linux systems.  

### gcc, g++ and make

https://gcc.gnu.org/

### ripgrep

https://github.com/BurntSushi/ripgrep

### bpytop

https://github.com/aristocratos/bpytop  

### golang 

https://go.dev/

### pyenv build dependencies

https://github.com/pyenv/pyenv/wiki#suggested-build-environment
