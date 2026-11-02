# Tasks

## 1. Structured status and grouping

- [ ] 1.1 Build disposable superproject/submodule fixtures for clean, changed checkout, tracked dirty, untracked dirty, staged-only, combined staged/unstaged, and ignore-settings cases; record raw Git output and expected sections in `verification.md`.
- [ ] 1.2 Update the custom status loader to parse NUL-delimited porcelain v2 with explicit submodule detection; verify fixture rows retain XY, gitlink identity, and separate commit/tracked/untracked flags, including deleted and unmerged gitlinks.
- [ ] 1.3 Preserve section IDs, real paths, ordinary-file metadata, and correct submodule group placement; verify the fixture matrix and ordinary rename/copy/conflict/untracked paths, including spaces and newlines, and record results alongside the parsing work.

## 2. Read-only inspection and source-specific opening

- [ ] 2.1 Add fresh state collection and a read-only submodule state buffer with full HEAD/index/checkout hashes, section context, and dirty flags; verify a three-commit fixture and dirty-only fixtures show distinct, accurate labels without changing repository state.
- [ ] 2.2 Handle added, deleted, missing, uninitialized, conflicted, and unreadable states, including child-root validation; verify unavailable values and conflict-stage hashes are labeled and errors never fall through to folder opening, and record the observations.
- [ ] 2.3 Wire `<CR>` through a Git-status-only command using existing Neo-tree configuration conventions; verify both sections open state, ordinary files and grouping directories retain existing actions, and filesystem submodules still navigate as directories.

## 3. Integration verification

- [ ] 3.1 Change child commits and dirty content externally, refresh Git status, and reopen inspection; verify current hashes, section movement, and removal of resolved rows, recording the exact refresh action in `verification.md`.
- [ ] 3.2 Review the scoped diff and run `openspec validate support-neotree-git-submodules --strict`; verify implementation stays in tracked configuration files, follows mapping conventions, leaves dependency pins unchanged, and the verification record covers the specification scenarios.
