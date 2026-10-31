# My Editor

## Install neovim itself

https://github.com/neovim/neovim/releases/latest

- Place appimage in `bin/` of this directory
- Rename it to `nvim.appimage`

# Start

Clone this repository:

```sh
git clone https://github.com/stryukovsky/my-editor ~/.config/nvim/
```

In `~/.config/nvim/` you need to run setup scripts:

Install basics with script on every platform

# Crossplatform Neovim preparations

**After installation of basics**, open neovim and run command

```
MasonInstall codelldb css-lsp  delve gopls html-lsp js-debug-adapter lua-language-server rust-analyzer sqls stylua typescript-language-server bash-language-server basedpyright goimports prettier clangd black gofumpt vscode-solidity-server texlab jdtls xmlformatter java-debug-adapter
```

JDTLS NEEDS VPN!!!


# Fedora / Asahi Fedora linux:

Important stuff with root password

```sh
sudo passwd root
```

And then reboot

Firstly make sure system is up-to-date:

Enable
[rpm fusion](https://docs.fedoraproject.org/en-US/quick-docs/rpmfusion-setup/)
packages.

RPM Fusion metalinks often hand out mirrors that time out from Russia. Pin them
to RU mirrors. `rpmfusion-*-release` updates restore the stock `.repo` files, so
run this again after those packages update. The `/country=/!` guard skips lines
that already have a country, so a second run does not append `&country=RU`
twice.

```sh
sudo sed -i.bak '/country=/!s|\(^metalink=.*basearch\)|\1\&country=RU|' /etc/yum.repos.d/rpmfusion-*.repo
```

```
sudo dnf config-manager disable fedora-cisco-openh264
sudo dnf upgrade -y
```

Execute every line separately!!!

```sh
chmod 700 bin/nvim.appimage
sudo bash setup/fedora/setup.sh
bash setup/common_tools/commons.sh

ln -sfr setup/fedora/zshrc.sh ~/.zshrc

# Of course firstly install them and then apply config
mkdir -p ~/.config/btop/
ln -sfr setup/common_tools/btop/btop.conf ~/.config/btop/btop.conf
mkdir -p ~/.config/kitty/
ln -sfr setup/fedora/kitty.conf ~/.config/kitty/kitty.conf

mkdir -p ~/.config/ranger/
ln -sfr setup/fedora/ranger/* ~/.config/ranger/
ln -sfr setup/fedora/ranger/colorschemes ~/.config/ranger/colorschemes

mkdir -p ~/.codex
ln -sfr setup/common_tools/codex/config.toml ~/.codex/config.toml

bash setup/common_tools/finalize.sh
bash setup/common_tools/ai.sh
bash setup/common_tools/git.sh

```

**Note**: read all stuff related to fedora below. Especially drivers and root
password

## Updating Fedora and development tools

Run as your normal user (the script uses sudo only for DNF):

```sh
~/.config/nvim/setup/fedora/update.sh --dry-run
~/.config/nvim/setup/fedora/update.sh
# If RPM Fusion metalink requests time out, bypass them for this run:
~/.config/nvim/setup/fedora/update.sh --rpmfusion-direct system
# Select only some groups:
~/.config/nvim/setup/fedora/update.sh node rust foundry python
```

`--rpmfusion-direct` uses the Yandex RPM Fusion mirror through temporary DNF
overrides, preserving enabled repositories and GPG checks. It does not edit
`/etc/yum.repos.d/`. The `country=RU` metalink setting above only filters the
returned mirrors; fetching the metalink itself still requires mirrors.rpmfusion.org.

Groups: `system`, `flatpak`, `node`, `rust`, `foundry`, `python`, `jvm`,
`shell`, `go`. With no groups, all detected groups run. Missing tools are skipped;
failed updates are reported at the end with a nonzero exit status. DNF, Flatpak,
and SDKMAN retain their confirmation prompts. Dry run prints actions without
updating or downloading anything; shell-function actions are named in its output.

- DNF updates RPM-managed apps and Go itself; Flatpak updates both user and system installations.
- nvm updates itself, then the **default Node major** (not every installed Node),
  migrates its globals, updates compatible npm, and runs `npm update -g`.
  Old Node versions remain available. Global npm dependencies retain semver limits.
- rustup updates itself and installed tracking toolchains/components. It does
  **not** update Cargo-installed applications or override project toolchain pins.
- foundryup updates itself and installs **stable** Forge/Cast/Anvil/Chisel,
  switching away from a nightly or custom build if one was selected.
- uv updates itself and `uv tool` environments; pipx tools update if pipx exists.
  Project virtual environments and managed Python interpreters are unchanged.
- SDKMAN updates itself and metadata, then offers SDK upgrades. Check prompts:
  Java, Gradle, and sbt upgrades can cross major versions. Coursier updates its apps.
- Oh My Zsh updates explicitly (automatic updates are disabled in this config).
- Go applications in `$GOBIN` or `$GOPATH/bin` are rebuilt at `@latest` using
  embedded package paths, including lazygit, lazydocker, and abigen on this machine.

Other installations found on this machine need separate update policies:

- Cargo apps: bulloak, cryo_cli, cargo-build-sbf, plus Git-installed avm and
  move-analyzer. Rustup does not update these. Review versions and source refs
  before reinstalling; avm is currently installed from an explicit Anchor tag.
- Solana/Agave, Anchor managed by avm, Aptos, and Surfpool: update explicitly for
  the project/network version you need.
- Standalone AI tools (Claude, Codex, Cursor Agent, OpenCode), Neovim AppImage,
  other AppImages, and manually unpacked tools are outside these managers.
  npm/uv updates only cover tools actually installed through those managers.
- Neovim plugins and Mason packages update inside Neovim. Review plugin changes
  and let lazy.nvim write `lazy-lock.json`.

Updater references: [nvm](https://github.com/nvm-sh/nvm),
[rustup](https://rust-lang.github.io/rustup/basics.html),
[Foundry](https://getfoundry.sh/getting-started/installation),
[uv](https://docs.astral.sh/uv/getting-started/installation/),
[SDKMAN](https://sdkman.io/usage/), and
[Coursier](https://get-coursier.io/docs/cli-install).


## Debugger for java

In `data` directory of neovim clone stuff and build jar

```sh
git clone https://github.com/microsoft/java-debug data/java-debug
cd data/java-debug
mvn clean install
```

## Install vllm

```sh
rm -rf ~/vllm
mkdir ~/vllm
cd ~/vllm
bash ~/.config/nvim/setup/fedora/vllm.sh
```

## Other Fedora stuff

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
- https://extensions.gnome.org/extension/1007/window-is-ready-notification-remover/
- https://extensions.gnome.org/extension/5353/window-state-manager/
- https://extensions.gnome.org/extension/7048/rounded-window-corners-reborn/
- https://extensions.gnome.org/extension/4559/quick-lang-switch/
- https://extensions.gnome.org/extension/3193/blur-my-shell/
- https://extensions.gnome.org/extension/19/user-themes/
  After installed, configure it:


```sh
bash setup/fedora/gnome.sh
```

## Fedora apps

https://github.com/storytold/pdfcraft
https://github.com/localsend/localsend

## Fedora themes 

https://github.com/vinceliuice/whitesur-gtk-theme 

In Gnome user themes extension set light theme


## Cuda NVIDIA & ollama

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

It seems that there is a problem with HDMI deepcolor which is enabled by default
in NVIDIA drivers. Idk if it’s related to higher refresh rates or HDMI versions
because changing from 2.0 to 1.4 also solves this (but with the 120hz limitation
of 1.4).

To disable deep color you can add “nvidia-modeset.hdmi_deepcolor=0” to
/etc/default/grub parameters like this GRUB_CMDLINE_LINUX="<other-parameters>
nvidia-modeset.hdmi_deepcolor=0" and then rebuid grub config using
grub2-mkconfig.

Also I don’t know if this can create issues to certain monitors or graphic cards
but this fixed it for me.

## Wireguard install

First try in UI Networks add VPN from file. Note file shall be named as
`somestring.conf`.

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
```

See [Termux setup](setup/termux/README.md) for mirror selection, SSH keys,
shell setup, and manual vault commands (`clv`, `cdv`, `wv`, `rv`).

# MACOS

Install brew https://brew.sh/ Install neovim from releases
https://github.com/neovim/neovim/releases  
Unzip it to ~/Tools/nvim Execute every line

```sh
sudo bash setup/macos/setup.sh
bash setup/common_tools/commons.sh
cp setup/macos/zshrc.sh ~/.zshrc

mkdir -p ~/.config/ghostty/
cp setup/macos/ghostty ~/.config/ghostty/config

mkdir -p ~/.config/kitty/
cp setup/macos/kitty.conf ~/.config/kitty/kitty.conf

mkdir -p ~/.config/bpytop/themes/
cp setup/common_tools/bpytop/light.theme ~/.config/bpytop/themes/

cp -r setup/macos/ranger ~/.config/
bash setup/common_tools/finalize.sh
bash setup/common_tools/ai.sh
bash setup/common_tools/git.sh
```

# Links

https://github.com/neovim/neovim  
https://alacritty.org/  
https://github.com/tmux/tmux  
https://gcc.gnu.org/ https://github.com/BurntSushi/ripgrep
https://github.com/aristocratos/bpytop  
https://go.dev/ https://github.com/pyenv/pyenv

## Neo-tree shared file clipboard

In the filesystem tree, `c` saves the current file or directory for copying;
visual `c` saves the selected entries together. Each copy replaces the previous
selection. `p` reads the latest saved paths, so you can paste in another Neovim
process or paste into several directories without copying again.

Paths are stored in `stdpath("data")/neotree-clipboard.json` (this configuration
uses `~/.config/nvim/data/neotree-clipboard.json`). Paste, Esc, local clipboard
clearing, text-path yanks (`y`), and exiting Neovim preserve this file. Only a new
file copy replaces it. Sources must still exist when pasting.

`x` remains a local cut: a pending cut takes priority over the saved copies and
moves its entries on paste. After it is pasted or cleared, `p` uses the shared
copy selection again. Destination selection and name-conflict prompts follow
Neo-tree's usual behavior.
