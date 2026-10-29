# Termux vault sync

Minimal setup: Git, OpenSSH, coreutils (`timeout`), util-linux (`flock`), cronie,
and termux-services. It leaves your shell, theme, fonts, and editor configuration
alone and does not install development tools.

From this checkout, inside Termux:

```sh
bash setup/termux/setup.sh
```

Grant storage access when Android prompts. Configure an SSH key with read/write
access to the vault and verify GitHub's host key interactively. Then clone the
vault if it is not already present:

```sh
ssh -T git@github.com
mkdir -p /storage/emulated/0/Documents
git clone git@github.com:stryukovsky/my-vault.git /storage/emulated/0/Documents/my-vault
bash "$HOME/.local/bin/vault-sync"
```

The cron key must work without an interactive passphrase prompt; cron does not
inherit a new shell's SSH agent.

## Bidirectional sync every three minutes

The installed `~/.local/bin/vault-sync` runs this sequence:

1. Stash local tracked and untracked edits, if any.
2. `git pull --no-rebase --no-edit` (merge remote updates).
3. Pop only the stash created by this run, if any.
4. `git add -A`, then `git commit -m "sync"` if staged changes exist.
5. `git push`, including when a previous run committed but could not push.

The default vault is `/storage/emulated/0/Documents/my-vault`. For a different
checkout, set `VAULT_DIR` when running setup; the cron installer saves that path
for the job. Direct invocation also accepts `VAULT_DIR`.

Overlapping runs are locked out. Network operations time out after two minutes.
Pull, stash-pop, commit, and push failures stop the run. Conflicts require manual
resolution; the job does not choose a side or discard edits. A failed pull/pop
preserves the sync stash and subsequent runs stop until it is recovered. Existing
unrelated stashes are left alone, including on clean runs.

To recover, inspect `git status` and `git stash list` in the vault. Resolve or
abort the interrupted merge, then restore the `termux-vault-sync` stash if still
present and resolve its conflicts. Once recovered, remove that stash from the
stash list before running sync again. Do not drop it before restoring your edits.

Setup preserves unrelated cron entries and replaces its own marked job on reruns:

```cron
*/3 * * * * /data/data/com.termux/files/usr/bin/bash "$HOME/.local/bin/vault-sync" >> "$HOME/.local/state/vault-sync/cron.log" 2>&1 # termux-vault-sync
```

The installer uses the device's `$PREFIX`. Check the schedule and service with:

```sh
crontab -l
sv status crond
tail -n 30 "$HOME/.local/state/vault-sync/cron.log"
```

Keep Termux running, permit background activity, and disable its Android battery
optimization. Setup enables crond and acquires `termux-wake-lock`; release it
with `termux-wake-unlock` when no longer needed. Android can still stop the app,
so exact timing is not guaranteed. Reboot autostart requires Termux:Boot.
Truncate the cron log occasionally if it grows large.

To update only the installed script and cron entry after editing this checkout:

```sh
bash setup/termux/install-cron.sh
```

To remove the job, delete the `# termux-vault-sync` line with `crontab -e`.
Disable crond with `sv-disable crond` only if no other jobs need it.

[Termux service management](https://github.com/termux/termux-services) ·
[Termux cron/background guidance](https://github.com/termux/termux-app/discussions/3297)
