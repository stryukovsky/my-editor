# Design

## Context

See proposal.md for motivation. `configs.neotree_git_groups` replaces Neo-tree's Git status item loader. It runs `git status --porcelain=v1 -z --untracked-files=all`, converts spaces to dots, groups entries using XY status, and emits every leaf as `type = "file"`. Leaf metadata contains no gitlink identity or submodule dirtiness. Git status has no local `<CR>` override and inherits normal opening behavior.

A disposable local repository confirmed that tracked-only and untracked-only submodule dirtiness both become ` M` with the current command. Porcelain v2 distinguishes these as `S.M.` and `S..U`. With `submodule.<name>.ignore=all`, the current command omits the dirty entry; `--ignore-submodules=none` exposes it. These explain concrete information loss and one omission mechanism; other reported bugs still need the fixture matrix below rather than assumed causes.

There are no published specs. Preserve the pending filesystem-viewer contract and all existing unrelated work.

## Goals / Non-Goals

**Goals:** Preserve Git's separate index/worktree meanings, identify gitlinks even when directories are absent, and inspect repository state without mutating it.

**Non-Goals:** Recursive status trees, submodule init/update/checkout commands, staging or revert redesign, filesystem-source status changes, or plugin forks.

## Decisions

### Parse structured Git status at the existing loader boundary

Use NUL-delimited porcelain v2 with `--untracked-files=all --ignore-submodules=none` for the custom Git status source. Preserve ordinary, rename/copy, unmerged, and untracked records, including rename source paths. Split fixed metadata fields without splitting filenames on whitespace. Normalize XY for existing renderers and navigation, but retain the submodule field, modes, and object IDs separately.

Porcelain v1 was rejected because its submodule representation loses tracked/untracked distinctions. Directory existence and `.git` directories are not identity checks: submodules commonly use `.git` files and may not be populated. Detect gitlinks using mode `160000` in status/index/HEAD metadata, supplementing deleted or unmerged entries where needed. Do not classify arbitrary nested repositories as submodules.

This view intentionally exposes changes even when repository ignore settings hide submodule dirtiness. The override is scoped to status reads for this source and does not change Git configuration. A clean submodule remains absent. Avoid one child-repository invocation per status row; collect extra hashes on inspection.

### Preserve group semantics and attach explicit submodule metadata

Keep real absolute paths, virtual section IDs, and existing ordinary-file grouping. Store gitlink identity and structured submodule flags on each applicable leaf. Index differences belong in Staged; worktree pointer differences or tracked/untracked dirtiness belong in Unstaged. The same submodule can appear in both, with section-specific context. Unmerged gitlinks remain conflicts, not ordinary staged changes. Never synthesize a staged change merely because child files are dirty.

Keep submodules as status leaves rather than expandable filesystem directories. Existing status badges can continue consuming XY; the inspection view supplies the distinctions XY cannot express.

### Override opening only in the Git status source

Register a Git-status-specific open command and `<CR>` mapping through Neo-tree configuration. It checks explicit gitlink metadata, opens the state view for submodules, and delegates ordinary entries and section directories to their current command. Do not alter common or filesystem commands. Any direct mappings needed during implementation must use `require "mappings.map"`.

Use `node.path` and the captured superproject root rather than virtual node IDs or a root inferred from the child directory. This prevents running parent queries against the submodule repository.

### Show a read-only snapshot with explicit hash meanings

Open a scratch buffer identifying the superproject, submodule path, and selected section. Display full hashes for the superproject HEAD gitlink, index gitlink, and checked-out submodule HEAD, alongside pointer-change, tracked-dirty, and untracked-dirty indicators. Resolve fresh state on each open so a previously rendered node cannot supply stale values. A staged entry compares HEAD to index; an unstaged entry compares index to checkout and describes child dirtiness.

Use parent Git metadata for recorded hashes and query the child only when its checkout is available and is actually the selected submodule. Git root discovery in an empty submodule directory can fall back to the parent; verify the child root before reading its HEAD. Mark unborn/absent/deleted/uninitialized values explicitly. For conflicts, show available base/ours/theirs gitlink hashes with labels instead of inventing a single index hash. An unreadable repository reports an error, never a clean state or fabricated hash. The buffer must not fall through to directory opening.

A dedicated state buffer is preferred over opening a commit picker or raw folder because dirty-only changes can occur with no commit change, and three different hashes can matter. A recursive diff UI is unnecessary for the requested state inspection.

## Risks / Trade-offs

- Changing the parser can regress renames, conflicts, or unusual names → compare ordinary-file rows and paths before/after using disposable fixtures, including spaces and newlines.
- Nested repository changes can escape parent filesystem notifications → verify the existing explicit Git status refresh always recollects state; do not add recursive watchers in this change.
- Repositories can change between Git reads → collect a fresh inspection snapshot and label unavailable values; a subsequent open or refresh recollects state.
- Explicitly exposing ignored submodule dirtiness adds rows some repositories previously hid → document this source-specific behavior in the verification record and leave repository settings untouched.
- Existing generic mutation commands may have their own submodule limitations → this proposal adds no mutation behavior; inspection must execute only read operations.

## Migration Plan

Apply only tracked config/helper changes and reload Neovim. No data migration or dependency update is required. Rollback restores the prior loader and source command definitions. Verify with temporary local repositories and record commands and observed results in this change's `verification.md`; no permanent test framework is needed.
