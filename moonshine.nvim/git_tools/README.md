# Periodic Git fetch

Fetches through `moonshine.git.job` without opening a UI. Starts five seconds after VimEnter and stops on VimLeavePre.

Successful fetches run every ten minutes. Failures retry with backoff (5s, 15s, 30s, 1m, 2m, 5m, 10m, 30m). Fetching skips repositories with unfinished merges, rebases, cherry-picks, reverts, bisects, Git lock files, or another active Git command.

Mappings: `<leader>gpf` starts fetching, `<leader>gpt` stops it, and `<leader>gpm` shows its status. The module also provides ahead/behind counts to the statusline.

## Git action queue

Supported Git actions share one busy variable and one in-memory queue for the
current Neovim session, even when working in different repositories. Nothing is
saved across restarts or shared with other Neovim processes.

Manual fetch and pull wait in order while busy. Pull still uses rebase and
autostash. A queued notification names the action and target repository; changing
the editor directory does not change that target. Background fetch uses the same
queue when idle. Timer ticks are skipped while busy and never accumulate.

Write actions are rejected immediately while busy, before input or confirmation
opens. This includes commit, push, checkpoint, merge, branch changes, amend, undo,
stash, stage/unstage, revert, and remote edits. For example, `<leader>gc` during a
fetch shows a busy warning without opening commit input. Rejected writes never
run later; retry after the current action finishes.

Opening write input marks the session busy until cancellation or completion.
Compound actions such as commit-and-push stay busy through all steps. Success,
failure, and cancellation release the session and start the next queued request.
Git mappings, Neo-tree Git aliases, and the custom branch/commit/remote pickers
share these rules. Browsing, previews, and yanking remain available.

External Git commands and third-party plugin internals are outside this queue.
Existing Git lock and unfinished-operation checks still apply to fetch/pull.
