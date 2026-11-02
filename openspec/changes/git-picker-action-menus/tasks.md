## 1. Integrate the existing remote picker

- [x] 1.1 Expose `show_remotes(opts)` through the pretty picker public module, retaining the internal remote entry point.
- [x] 1.2 Route the Git remotes mapping through the facade and preserve forwarded Neo-tree state.

## 2. Implement branch action menus

- [ ] 2.1 Capture selection, multi-selection, cwd, and reopen options before closing the list; share action logic between direct keys and menu choices without stale prompt access.
- [ ] 2.2 Add the ordered branch menu with Switch branch first and initially selected; replace the default selection action for both Normal and Insert mode Enter.
- [ ] 2.3 Retain `d`, `m`, `r`, `R`, and `y`, existing scope/confirmations, tracking behavior, and custom `attach_mappings` ownership.

## 3. Implement commit action menus

- [ ] 3.1 Capture commit action context and add the ordered menu with Checkout commit (detached HEAD) first and initially selected.
- [ ] 3.2 Retain `a`/`r`, `x`/`u`, `s`, and `y`; preserve execution-time HEAD checks, message-only amend, staged-change protection, and stash recovery.
- [ ] 3.3 Restore list context on menu cancellation and after menu-based yank for both pickers; update prompt hints.

## 4. Focused verification

- [ ] 4.1 Verify Enter opens actions without mutations, and Enter twice invokes the old action for branches and commits with the actual configured selector.
- [ ] 4.2 Compare direct-key and menu execution for every existing action, including multi-branch deletion and multi-selection yank, using disposable Git repositories.
- [ ] 4.3 Verify empty lists, canceled menus/input/confirmations, local and remote branches, older commits, changed HEAD, initial-commit undo, and Git failures.
- [ ] 4.4 Verify query/selection/cwd/ref/limit/preview overrides survive menu cancellation, and Insert-mode action letters remain prompt input.
- [ ] 4.5 Verify MiniDiff branch → commits → merged review retains its existing one-Enter steps and custom previews.
- [ ] 4.6 Run Lua syntax, relevant formatting/diff checks, and strict OpenSpec validation; record focused verification results.
