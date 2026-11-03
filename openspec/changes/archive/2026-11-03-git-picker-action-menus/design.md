# Design

## Context

`remote_picker.open` lists remotes in Telescope. Normal-mode `d`, `r`, `u`, and `s` execute an action for the selected row; Enter closes the list and schedules `vim.ui.select` for the row's actions. Canceling that menu reopens the remote list.

The remote implementation already belongs to `telescope_pretty_picker/`, but the Git mapping calls the internal module directly. The immediate refactor adds the same public facade used by branches, commits, and search. Keep `.open(opts)` available for compatibility.

Branch Enter currently calls `git_switch_branch`; commit Enter calls `git_checkout`. Their action functions currently read selection and cwd from a live Telescope prompt. Both pickers allow callers to replace `attach_mappings`; MiniDiff history uses this to select review branches and commits rather than switch or checkout.

## Goals / Non-Goals

Goals:

- Use the remote picker's list → action menu interaction for standard branch and commit pickers.
- Preserve quick action keys and make Enter twice equivalent to the previous Enter action.
- Preserve row identity, repository scope, multi-selection semantics, and existing action checks across UI transitions.

Non-goals:

- Adding Git actions, changing confirmations, enabling older-commit undo, or redesigning previews.
- Changing custom history/review mappings or `telescope.builtin` pickers.
- Introducing a generic picker framework or changing the remote menu's existing order and operations.

## Decisions

### Public remote entry point

Add `show_remotes(opts)` to `telescope_pretty_picker.init`, forwarding options to the existing module. Use it from `<leader>gmr`; Neo-tree's `mr` alias continues to forward its state. No file move is needed because ownership is already correct.

### Ordered, explicit action menus

Use `vim.ui.select` after closing the Telescope list, as the remote picker does. The action selector must start in Normal mode with its first row focused so the next Enter chooses it. Verify this against the configured `vim.ui.select` implementation.

| Picker | Menu order | Direct keys retained on the list |
| --- | --- | --- |
| Branches | Switch branch; Delete branch; Merge branch; Rename branch; Rebase onto branch; Yank branch name | `d` delete, `m` merge, `r` rename, `R` rebase, `y` yank |
| Commits | Checkout commit (detached HEAD); Rename HEAD commit; Undo HEAD (keep changes staged); Undo HEAD and stash changes; Yank commit SHA | `a`/`r` rename, `x`/`u` undo, `s` undo and stash, `y` yank |

Keep labels explicit about HEAD restrictions and detached checkout. Keep restricted actions visible for discoverability; attempting one on an ineligible row uses the same guard and notification as its direct key. Existing mutation confirmations still follow action selection.

Replace the default selection action rather than binding Enter only in Normal mode, so Normal and Insert mode Enter both open the action menu. Direct letter shortcuts remain Normal-mode actions and do not steal prompt input.

### Capture context before closing the list

Snapshot the selected entry, resolved repository cwd, relevant multi-selected entries, and reopen options before closing the prompt. The menu must never call a handler that tries to read a destroyed prompt buffer or the newly opened action picker as the original list.

Refactor the smallest necessary boundary so direct keys and menu choices reach the same action implementation with captured context. Branch deletion retains its existing multi-selection behavior. Other actions retain their current focused-row scope. Yank retains full commit hashes, branch names, register targets, and multi-selection behavior from `mappings.telescope.yank`.

Do not close an already closed prompt a second time. Keep scheduled UI transitions, the existing error wrapper's intent, and Git notifications without allowing an error to silently act on another picker.

### Cancel returns to the original list

Canceling the action menu performs no Git command or yank and reopens the originating list. Preserve its query, selected row when still present, repository, ref/limit/pattern/remote visibility, previewer, titles, and caller options. A changed or missing row must be handled safely rather than silently substituting another target. Menu-based yank returns to the same list; direct `y` continues to keep the list open.

### Custom mappings retain ownership

Preserve the early return to caller-supplied `attach_mappings`. Do not wrap or replace Enter for these callers. MiniDiff branch selection must still open commits and MiniDiff commit selection must still start a review in one Enter.

## Risks / Trade-offs

- Closing Telescope invalidates prompt-dependent handlers. Capture action context first and exercise both menu and direct routes.
- `vim.ui.select` may inherit a different mode or selection policy. Verify first-row focus and double Enter with the actual configured selector.
- Refactoring deletion or yank can lose multi-selection. Check focused-row and multi-selected cases explicitly.
- Commit state can change while an action menu is open. Reuse HEAD checks at execution time and the rename handler's second HEAD check after input.
- Reopening can lose caller scope. Retain original options before the current picker functions strip them for Telescope.

## Rollout

The remote facade can land independently and is already integrated. Implement menus for standard branches and commits next, verify custom review workflows, then mark the remaining tasks complete. Roll back menus by restoring their previous default Enter handlers; the remote public API can remain.
