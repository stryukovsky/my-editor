# Termux setup and Obsidian vault

Run from this Neovim config checkout inside Termux:

```sh
bash setup/termux/setup.sh
```

Grant Android storage access, then choose a nearby mirror or regional mirror
group in `termux-change-repo`. Setup installs Git, OpenSSH, Zsh, Neovim, fzf,
tmux, ranger, and htop; installs the shell, terminal colors, tmux, and ranger
configs; and selects Zsh as the login shell. Existing config files get a
`.before-termux-setup` backup once. Oh My Zsh is used if already installed.

Setup removes the previous marked vault cron job and installed `vault-sync`
script. Unrelated cron jobs are preserved; crond is disabled and the old wake lock is released only when removing
our job leaves no other entries. No scheduled sync or wake lock is installed.

An Ed25519 SSH key is generated interactively if absent. Existing keys are
preserved. Setup prints the public key last: add it to
[GitHub SSH keys](https://github.com/settings/ssh/new), then run:

```sh
exec zsh
ssh -T git@github.com
clv  # only if the vault is not already cloned
cdv
```

The vault path is always `/storage/emulated/0/Documents/my-vault`.
`clv` clones `git@github.com:stryukovsky/my-vault.git` there. If it already exists,
use it directly; clone does not replace an existing directory.

| Command | Behavior |
| --- | --- |
| `cdv` | Change to the vault directory. |
| `clv` | Clone the vault from GitHub over SSH. |
| `wv` | Stage all changes/deletions, commit if needed, and force-push HEAD to GitHub main. |
| `rv` | Fetch GitHub main and reset the current branch and tracked files to it. |

Both commands use `git@github.com:stryukovsky/my-vault.git` directly, so no
configured remote or upstream is required. `clv` explicitly clones main with
an origin remote.

`wv` overwrites remote main, including commits missing locally. A clean working
tree still pushes existing local commits.

`rv` runs `git reset --hard FETCH_HEAD` after a successful fetch. It discards
staged and unstaged tracked changes and replaces local branch history with
remote main. Untracked files can also be removed if they obstruct tracked files
from the fetched commit. A failed fetch leaves local files unchanged.

To select another package mirror later, run `termux-change-repo` again.
