# Proposal

## Why

The remote picker supports both fast action keys on a row and Enter to discover its actions. Branch and commit pickers should offer the same interaction without losing their current shortcuts or default actions.

## What Changes

- Expose the existing remote picker as `telescope_pretty_picker.show_remotes(opts)` and route the Git remotes mapping through it. Keep remote behavior unchanged.
- Make Enter in the standard branch and commit pickers open an action menu for the focused row.
- Put the old Enter action first and select it initially: **Switch branch** for branches, **Checkout commit (detached HEAD)** for commits. Enter twice performs the former action, subject to the same existing checks.
- Keep direct action keys on the main list and advertise both interaction paths.
- Reuse existing action behavior, confirmations, HEAD restrictions, previews, and Git error handling.
- Preserve custom `attach_mappings` consumers, including MiniDiff history/review, whose Enter behavior remains theirs to define.

## Capabilities

### New Capabilities

- `git-picker-actions`: Row action menus and direct shortcuts for pretty Git pickers, including default action ordering and preservation of selection context.

### Modified Capabilities

None. There are no published specs under `openspec/specs/`.

## Impact

- Immediate integration: `lua/telescope_pretty_picker/init.lua` and `lua/mappings/git.lua`. The remote implementation already resides in `lua/telescope_pretty_picker/remote_picker.lua`.
- Planned implementation: `branch_picker.lua`, `commit_picker.lua`, and a small shared helper only if needed within `telescope_pretty_picker/`.
- Compatibility checks: `lua/configs/minidiff_history.lua`, `lua/mappings/telescope/defaults.lua`, and `lua/mappings/telescope/yank.lua`.
- No new plugin dependencies, Git operations, or changes to built-in Telescope Git pickers. Branch/commit action menus are specified here, not implemented as part of preparing this change.
