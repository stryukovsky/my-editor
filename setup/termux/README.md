# Termux setup

Run from this Neovim checkout **in Termux**, without sudo:

```sh
bash setup/termux/setup.sh
```

Grant Android storage access when prompted. The script upgrades packages,
installs terminal tools, sets Zsh as the shell, and installs the configs below.
Existing config files get a one-time `.before-termux-setup` backup.
Open a new shell after setup.

## Fedora features carried over

| Fedora setup | Termux setup |
| --- | --- |
| Zsh + Oh My Zsh philips, fzf, aliases | Same prompt, portable plugins, `ff`/`mc`, `o=termux-open`, `vim=nvim` |
| AdwaitaMono Nerd Font, Material wheat colors | `~/.termux/font.ttf` and `colors.properties`; matching Ranger/tmux colors |
| tmux navigation | Same Ctrl navigation and visual copy; OSC 52 clipboard, compact status bar, no desktop plugin dependencies |
| Ranger | Wheat scheme, copy/cut/paste, rename/delete; Android file opening instead of Kitty/GNOME commands |
| Neovim, ripgrep, fd-find | `neovim`, `ripgrep`, `fd`, `tree-sitter` |
| GCC/build tools | Termux Clang, make, CMake, Ninja, pkg-config |
| nvm / rustup / desktop language installs | Android-native `nodejs-lts`, Python, Go, Rust packages |
| btop | htop (Termux's maintained process monitor; Android limits process visibility) |
| pandoc, ImageMagick, debugger, coverage, PostgreSQL, Maven | Install if available in this device's current package metadata |
| cron | cronie supervised by termux-services |

GNOME, Wayland, desktop terminals, Flatpak, Fedora repositories, kernel VPN
configuration, and desktop clipboard helpers are not installed. Android owns
those system/desktop functions. Do not run `setup/common_tools/commons.sh` here:
its desktop runtime installers are not the Termux package workflow.

Use `update-termux` in Zsh to upgrade Termux packages and Oh My Zsh. Package
upgrades also update the packaged language runtimes.

## Vault update every three minutes

Setup installs `~/.local/bin/vault-sync` and this marked cronie entry, preserving
unrelated jobs and replacing its own entry on subsequent runs:

```cron
*/3 * * * * /data/data/com.termux/files/usr/bin/bash "$HOME/.local/bin/vault-sync" >> "$HOME/.local/state/vault-sync/cron.log" 2>&1 # termux-vault-sync
```

The prefix is taken from `$PREFIX` during installation. The vault defaults to
`/storage/emulated/0/Documents/my-vault`. This job **pulls only**, with
`git pull --ff-only`: it never commits, stashes, rebases, or pushes local edits.
Dirty checkouts are skipped. Concurrent runs are locked out, network operations
time out, and SSH is noninteractive with strict host-key checking.

First configure an SSH key authorized for `stryukovsky/my-vault`, verify GitHub's
host key interactively, and clone using the shell helper:

```sh
ssh -T git@github.com
pullvault
bash "$HOME/.local/bin/vault-sync"
crontab -l
sv status crond
tail -n 30 "$HOME/.local/state/vault-sync/cron.log"
```

The cron key must work without an interactive passphrase prompt (cron does not
inherit a new shell's SSH agent). Shared storage must remain accessible.
`pushvault` explicitly stages and commits local changes, then rebases and pushes;
use it manually when you want to publish phone edits.

Keep Termux running, allow background activity, and disable Android battery
optimization for Termux. Setup acquires `termux-wake-lock` to help cron run while
the screen is off; release it with `termux-wake-unlock` when no longer needed.
Android can still stop the app, so this is not an exact timing guarantee. Services
restart on a new Termux shell; reboot autostart requires the separate Termux:Boot
app. The cron log is a regular file; truncate it occasionally if it grows large.

To reinstall only the scheduled job after packages are installed:

```sh
bash setup/termux/install-cron.sh
```

To remove it, run `crontab -e` and delete the `# termux-vault-sync` line. Disable
crond with `sv-disable crond` only if no other jobs need it.

Sources: [Termux package definitions](https://github.com/termux/termux-packages/tree/master/packages),
[service management](https://github.com/termux/termux-services),
and [Termux maintainer guidance on cron/background execution](https://github.com/termux/termux-app/discussions/3297).
