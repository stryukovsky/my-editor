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

## Typed floating input

`vim.ui.input` (also `vim.input`) accepts an optional `filetype`. Omit it or
pass `""` to keep ordinary prompts free of autocomplete. A nonempty value sets
the buffer filetype, runs its FileType hooks, and enables native completion;
Tree-sitter/LSP support still depends on the installed parser/server.

```lua
vim.ui.input({ prompt = "Commit message: ", filetype = "gitcommit", cwd = vim.fn.getcwd() }, function(value)
  -- nil means cancelled; otherwise value is the confirmed message.
end)
```

The commit action uses this automatically. Git commit inputs offer the current
branch (from the supplied repository `cwd`) and installed `gitcommit` snippet
prefixes such as `feat`, `fix`, and `chore`. Templates expand their first line
only, preserving the single-line prompt. Enter accepts a selected suggestion;
press Enter again to submit. Tab/Shift-Tab move through snippet placeholders.
Ctrl-Space opens completion manually. Detached HEAD/non-Git directories omit
the branch suggestion. Filetype/Tree-sitter alone do not generate Git suggestions.

The commit popup uses immediate native completion while the input is open. This
avoids a blank menu frame during typing with a nonzero autocomplete delay. The
previous global delay is restored on submit, cancellation, or window close;
explicit option changes made while the input is open are preserved.

## Native completion

Native completion targets Neovim 0.12.6; Blink remains disabled. Ranking follows:

1. Exact case-sensitive/case-insensitive names, case-sensitive/case-insensitive prefixes, then fuzzy matches.
2. Distinct identifier words elsewhere on the current line, then fine fuzzy score. `User` near `create` favors `createUser` over `createCat`; exact `createCat` still wins when typed explicitly.
3. Nondeprecated items, single-server `sortText` (label when missing), conservative syntax fit, ordinary items before snippets, and stable final ties.

Current-line affinity uses whole camel/Pascal/acronym/snake identifier components;
repetition, query words, language keywords, comments, and strings do not boost it.
It uses only the current line, not a project-wide frequency or semantic model.
Language node groups, keyword exclusions, and parser fixtures live in
[`lua/native_completion/languages/*.json`](lua/native_completion/languages/README.md).
The shared JSON Schema is `schemas/native-completion-language.schema.json`.

Lua, TypeScript/TSX, Go, Rust, Scala, Java, Python, C, C++, and Solidity have
syntax adapters. Lua handles member/method access; the other mappings also handle type
positions and imports/includes. C and C++ are the mappings used with clangd.
TSX inherits TypeScript rules and adds JSX parser fixtures. Unknown syntax, missing parsers, and unsupported
or ambiguous injected languages give neutral hints. An available parser is used;
completion does not install one. Tree-sitter hints do not prove type compatibility
or lexical scope. Multiple attached completion servers omit server sort keys
because different servers' keys do not share a ranking scale.

The menu is limited to 10 item rows and 70 content columns, shrinking on narrow
screens. Display labels are limited to 45 cells and descriptions to 24 cells.
Formatting changes display fields only: full insertion, native snippets,
auto-import edits, commands, documentation, and distinct same-label items remain.
The existing wheat palette and rounded opaque popup are retained.

In ordinary enabled editing buffers, `<C-x><C-n>` cancels an open LSP selection
and starts current/window/loaded-buffer word completion. `<C-Space>` requests
LSP/manual completion; Enter accepts a selected item and otherwise inserts a
newline. Ctrl-Enter accepts the selected or first item. Automatic fallback after
an empty LSP response is intentionally not enabled. Floating input opts into
completion through its `filetype`; terminal command completion keeps its sources.

Compared with the old kind-first policy, an exact function can now outrank a
variable. Compared with native default fuzzy sorting, current-line identifier
affinity can favor `createUser` even when shorter `createCat` has a better fuzzy
score. `fuzzy,nosort,noselect` keeps this explicit order and avoids implicit acceptance.

Focused fixtures (run from this configuration directory):

```sh
nvim --headless -u NONE -i NONE -l tests/native_completion_languages.lua
nvim --headless -u NONE -i NONE -l tests/native_completion.lua
uv run --with pynvim python tests/native_completion_integration.py
uv run --with pynvim python tests/native_input_completion.py
```

The mapping suite checks all language JSON definitions against their installed
grammars and runs their embedded parser fixtures. The core suite checks
ranking, Unicode display, comparator laws, caching, and a 1,000-item profile.
The integration suite drives a running Neovim with a temporary fake LSP, testing native
acceptance, auto-imports, snippets, commands, documentation, popup limits, and
English/Russian shortcuts. `pynvim` is a test dependency only. Integration also
exercises the locally installed Lua, TypeScript, and Go servers when available.
See the [mapping format and fixture guide](lua/native_completion/languages/README.md)
to add another grammar without changing the Lua context engine.

The input regression suite checks native rendered frames while typing, snippet
acceptance, submission, and completion-delay restoration on input cleanup.


## Markdown math symbols

Rendering is configured off by default. `<leader>mdt` toggles it for this buffer;
`<leader>mdr` opens and enables a rendered preview. The same math rendering is
available in `todotxt-preview` buffers.

Inside `$...$` or `$$...$$`, LaTeX symbols display as Unicode: for example,
`$\alpha \cdot x \Rightarrow \infty$` displays as `α ⋅ x ⇒ ∞`, with spaces in place of the dollar delimiters.
Supported symbols include Greek letters and variants, arrows, comparisons,
arithmetic, sets, logic, calculus, delimiters, and named functions such as `\sin`
and `\log`. Dots retain their distinct forms: `\cdot` → ⋅, `\bullet` → •,
`\ldots` / `\dots` → …, `\cdots` → ⋯, `\vdots` → ⋮, and `\ddots` → ⋱.
`\left` / `\right` are hidden while their delimiters remain, so
`$\left\langle x \right\rangle$` displays as `⟨ x ⟩`. A dot delimiter in
`\left.` or `\right.` is invisible.

This only changes the display. Buffer and saved text keep the original LaTeX;
code spans, code fences, and prose remain literal, and Markdown backticks stay
visible. Fractions use a linear division sign: `\frac{xy}{x+a}` → `(xy) ÷ (x+a)`;
`\dfrac` and `\tfrac` work the same way. Roots use `\sqrt{xy}` → `√(xy)`,
including nested fractions and roots. `\quad` / `\qquad` insert two / four spaces;
small spacing commands and escaped spaces are also supported. Named functions
include `\min` and `\max`. Unknown commands, superscripts, subscripts and accents
(such as `\bar p`) stay as written. Indexed roots such as `\sqrt[3]{x}` remain
literal. Formula text and replacements share the normal text foreground, refreshed
on theme changes. No external LaTeX converter is required. The implementation lives in
`lua/configs/markdown-math.lua`; no render-markdown plugin source is patched.

Focused checks (using the parsers and plugin installed in this config):

```sh
nvim --headless -u NONE -i NONE -l tests/markdown_math.lua
uv run --with pynvim python tests/markdown_math_ui.py
```

While math rendering is enabled, inline `$` delimiters display as spaces. The
opening display-math `$$` displays as the LaTeX Nerd Font icon `` followed by a
space; the closing `$$` displays as two spaces. Toggle rendering off to reveal
the original delimiters. Code and escaped literal dollar signs are unaffected.
