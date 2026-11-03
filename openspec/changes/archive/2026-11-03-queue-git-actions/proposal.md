# Proposal

## Why

Committing during a background fetch currently lets the user enter a message before rejecting the commit with a busy warning. Git actions need a consistent policy that queues fetch/pull requests and rejects write actions before asking the user for input.

## What Changes

- Classify fetch and pull as queueable actions. Preserve pull's existing `--rebase --autostash` behavior; this policy does not imply that pull is read-only in Git.
- Use one in-memory queue and one shared busy variable for the current Neovim session to serialize supported Git actions. Nothing is persisted across restarts. Queue explicit fetch/pull requests in arrival order when an action is active, including a background fetch.
- Block write actions immediately while the session is busy: commit, commit-and-push, checkpoint, merge, push, rename, amend, and other existing mutations. Never queue these for later execution.
- For example, pressing `<leader>gc` during a fetch shows a busy warning immediately and opens no commit-message input.
- Apply the same admission policy to Git mappings, Neo-tree aliases, and branch/commit/remote picker actions, before action-specific input or confirmation.
- Run background fetch through the same queue when idle; skip timer ticks while busy, without special priority rules.
- Protect admitted interactive write flows from a background fetch starting while the user types; release their reservation on cancellation, completion, or failure.
- Keep browsing and previews available. Report queued requests and the active action that blocks a write.

## Capabilities

### New Capabilities

- `git-action-scheduling`: Session-wide Git action serialization, fetch/pull queueing, and early admission of interactive write actions.

### Modified Capabilities

None. There are no published specs under `openspec/specs/`.

## Impact

- `moonshine.nvim/git_tools/lua/moonshine/git/commands.lua` and `fetch.lua`: replace separate busy/queue handling with shared scheduling and background-fetch completion integration.
- A shared scheduling module under `moonshine.nvim/git_tools/lua/moonshine/git/`.
- Mutation handlers under `moonshine.nvim/telescope_pretty_picker/lua/telescope_pretty_picker/`: use the same early guard for direct shortcuts and action menus.
- Existing mappings and Neo-tree aliases retain their keys and repository selection. Existing stage/unstage queueing becomes early rejection under the write policy.
- No new dependencies, changes to Git command arguments, or lockfile edits.
