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
| `wv` | Stage all changes/deletions, commit if needed, and force-push the local branch over its tracked remote branch. |
| `rv` | Stash tracked/untracked edits, fetch the tracked remote branch, fast-forward to it, then pop this run's stash. |

`wv` deliberately overwrites remote history, including commits missing locally.
It never pulls first. A clean working tree still pushes existing local commits.
Both commands use the configured upstream remote and branch, falling back to
`origin` and the current branch name if no upstream is configured.

`rv` does not push. Diverged committed histories stop the fast-forward; fetch or
update failures preserve the new stash and print its ID. A stash-pop conflict
also leaves the stash available. Inspect `git status` and `git stash list`, then
restore/resolve it manually. A clean run never pops an unrelated existing stash.
Pending merges, rebases, or unresolved conflicts must be resolved first.

The old `pushvault` / `pv` names now call `wv`; `pullvault` calls `rv`.
To select another package mirror later, run `termux-change-repo` again.
