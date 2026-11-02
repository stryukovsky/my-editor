# Verification

Verified on 2026-11-02 using headless Neovim, installed Telescope and
`telescope-ui-select`, the repository's `configs.telescope` setup, and disposable
Git repositories under `/tmp`. Picker windows, selection, multi-selection,
Normal-mode shortcut callbacks, and default selection actions were exercised
against the real plugins. Notifications were captured; confirmations and text
input were controlled; clipboard writes used an in-memory provider. No changes
were made to this configuration repository's Git history.

## Results

All 56 focused checks passed (26 action-route checks, 25 context/guard/history
checks, and 5 additional restoration/safety checks).

- Branch and commit Enter open ordered action menus without a mutation. The
  configured selector starts in Normal mode with action 1 focused. Choosing that
  default switches a branch or detaches at the selected commit. The actual
  Insert-mode Enter mapping also opens the menu; action letters have no
  Insert-mode bindings.
- Direct shortcuts and menu actions share execution paths. Checked branch
  switch, multi-branch deletion, merge, rename, rebase, and multi-selection yank;
  commit checkout, both rename aliases, both soft-undo aliases, undo and stash,
  and multi-selection yank. Git refs, staged files, stash contents, and register
  values were checked after actions. Direct yank keeps its original list open.
- Canceling a menu restores query, focused row, resolved cwd, ref, limit, titles,
  caller completion callbacks, and preview override. Repeated cancellation also
  restores the focused row. Menu yank restores the list and multi-selection.
  Changing editor cwd while a menu is open does not redirect the Git operation.
- Checked remote-tracking branch creation, local-only rename guards, merge
  tracking warnings, canceled confirmations and input, older-commit guards,
  initial-commit undo rejection, current-HEAD checkout no-op, and tracked-change
  protection for undo and stash.
- HEAD changes while the menu is open prevent a stale rename; a second HEAD
  change during text input also prevents amending the replacement commit.
  Message-only amend leaves previously staged files out of the commit.
- Injected stash failure restores HEAD and reports recovery. A branch removed
  while its menu is open produces the existing Git error rather than switching
  to another row. Missing rows on cancellation and empty repositories/filtered
  lists are safe.
- Ran the actual MiniDiff history branch picker, selected a branch in one Enter,
  then selected commits and reached the merged-review callback in one Enter.
  History's custom previews and mappings remain owned by its existing code.
  The review-start callback was captured instead of opening the review UI.
- The remote public facade and Git/Neo-tree forwarding were already implemented
  and remain unchanged.

## Static checks

- Neovim `loadfile` succeeds for all four changed Lua modules.
- `stylua --check` succeeds for all four changed Lua modules.
- `git diff --check` succeeds.
- `openspec validate git-picker-action-menus --strict` succeeds.

The focused verification drivers live in `/tmp/verify_git_menus*.lua`; no
permanent test framework or plugin dependency was added. These checks exercise
headless picker behavior; they do not assert terminal rendering or a full
interactive MiniDiff review session.
