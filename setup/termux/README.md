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
| `rv` | Fetch the tracked remote branch, discard unstaged tracked edits, then fast-forward to the fetched version. |

`wv` deliberately overwrites remote history, including commits missing locally.
It never pulls first. A clean working tree still pushes existing local commits.
Both commands use the configured upstream remote and branch, falling back to
`origin` and the current branch name if no upstream is configured.

`rv` permanently discards unstaged changes to tracked files, including deletions,
even when the remote has no new commits. Staged changes and untracked files are
preserved; if they obstruct the fast-forward, Git stops the update. No stash is
created or reapplied. A failed fetch or a fetched branch that cannot fast-forward
the local branch stops before discarding edits. An update failure after that
point does not restore discarded edits. `rv` does not push.
Pending merges, rebases, or unresolved conflicts must be resolved first.

The old `pushvault` / `pv` names now call `wv`; `pullvault` calls `rv`.
To select another package mirror later, run `termux-change-repo` again.
