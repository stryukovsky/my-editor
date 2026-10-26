# Periodic Git fetch

Fetches through `configs.gitutils.job` without opening a UI. Starts five seconds after VimEnter and stops on VimLeavePre.

Successful fetches run every ten minutes. Failures retry with backoff (5s, 15s, 30s, 1m, 2m, 5m, 10m, 30m). Fetching skips repositories with unfinished merges, rebases, cherry-picks, reverts, bisects, Git lock files, or another active Git command.

Mappings: `<leader>gpf` starts fetching, `<leader>gpt` stops it, and `<leader>gpm` shows its status. The module also provides ahead/behind counts to the statusline and remote-behind banner.
