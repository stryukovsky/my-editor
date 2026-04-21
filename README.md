# My Editor

Clone this repository:

```sh 
git clone https://github.com/stryukovsky/my-editor ~/.config/nvim/
```

In `~/.config/nvim/` you need to run setup scripts:  

## Start 
Install basics with script on every platform  

### Fedora / Asahi Fedora linux:  

Important stuff with root password  

```sh
sudo passwd root
```

And then reboot  

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
cp setup/fedora/zsh.sh ~/.zshrc
mkdir -p ~/.config/ghostty/
cp setup/fedora/ghostty ~/.config/ghostty/config
cp -r setup/ranger ~/.config/
bash setup/finalize.sh
bash setup/ai.sh

```

Install plugins in tmux (`<prefix>I`).  
Then copy theme for tmux-powerline.  

```sh
cp setup/tmux/my-theme.sh ~/.tmux/plugins/tmux-powerline/themes/
```

**Note**: read all stuff related to fedora below. Especially drivers and root password

# Neovim preparations
After installation of basics, open neovim and run command
```
MasonInstall codelldb css-lsp  delve gopls html-lsp js-debug-adapter lua-language-server rust-analyzer sqls stylua typescript-language-server bash-language-server basedpyright goimports prettier clangd black gofumpt vscode-solidity-server texlab jdtls xmlformatter
```

## Debugger for java 

In `data` directory of neovim clone stuff and build jar

```
git clone https://github.com/microsoft/java-debug data/java-debug
cd data/java-debug
mvn clean install
```

# Install vllm

```sh
rm -rf ~/vllm
mkdir ~/vllm
cd ~/vllm
bash ~/.config/nvim/setup/fedora/vllm.sh
```

# Other Fedora stuff

Note: NVIDIA may not work until secure boot is not configured properly.  
Note: [RPM Fusion](https://rpmfusion.org/Howto)

## AWG

Setup using awg-quick  

https://github.com/amnezia-vpn/amneziawg-tools

https://github.com/amnezia-vpn/amneziawg-go


Remove `I2 = `-like lines before copying!!!  
```sh
sudo cp /full/path/to/config.conf /etc/amnezia/amneziawg/awg0.conf
sudo WG_QUICK_USERSPACE_IMPLEMENTATION=amneziawg-go awg-quick up awg0
```

## Gnome look

Install plugins

- https://extensions.gnome.org/extension/7065/tiling-shell/
- https://extensions.gnome.org/extension/1460/vitals/
- https://extensions.gnome.org/extension/1160/dash-to-panel/
- https://extensions.gnome.org/extension/6994/keyboard-reset/
After installed, configure it:  

```sh 
bash setup/fedora/gnome.sh
```

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

# Android Termux stuff

Setup the environment:  

```sh 

bash setup/termux/setup.sh
cp setup/zshrc.sh ~/.zshrc
```

# Links 

https://github.com/neovim/neovim   
https://alacritty.org/  
https://github.com/tmux/tmux  
https://gcc.gnu.org/
https://github.com/BurntSushi/ripgrep
https://github.com/aristocratos/bpytop  
https://go.dev/
https://github.com/pyenv/pyenv


