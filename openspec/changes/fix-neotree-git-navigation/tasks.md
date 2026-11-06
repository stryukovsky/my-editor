## 1. Completed investigation

- [x] 1.1 Trace `focus_next_git_modified`, the Git parser, and sync/async status
      collection; identify directory-only `normal` records rejected by the file
      predicate.
- [x] 1.2 Inspect the active config: record the existing `before_git_status`
      workaround and enabled untracked setting so implementation migrates rather
      than duplicates them.
- [x] 1.3 Compare `utils.sort_by_tree_display` with `file_items.advanced_sort`;
      verify default depth-first order, selected-directory misclassification,
      and case-insensitive order divergence in headless Neovim.
- [x] 1.4 Trace target selection and reveal: identify clean-anchor wraparound
      and missing-status assumptions; confirm existing focus/reveal expands
      collapsed ancestors.

## 2. Make untracked collection complete inside the plugin

- [x] 2.1 In `git/init.lua`'s `make_git_status_cmd`, choose `all` for requests
      that otherwise use `normal` when `consider_untracked_as_git_change` is
      enabled; preserve explicit `no` and the disabled-setting behavior.
- [x] 2.2 Check generated arguments for `M.status`, first async fast scan, first
      async full scan, and subsequent async refresh. Expected enabled sequence:
      sync `all`; async `no` then `all`; refresh `all`.
- [x] 2.3 Verify the parser/cache contains individual `?` leaves under a wholly
      new nested folder and excludes ignored descendants; repeat after
      creating/removing a leaf and refreshing.
- [x] 2.4 Remove only the `before_git_status` argument-rewrite handler from
      `lua/configs/neotree.lua` once plugin-owned collection passes; retain the
      enabled setting and other handlers.

## 3. Fix navigation ordering and eligibility

- [x] 3.1 In filesystem `commands.lua`, separate the current-path anchor from
      eligible Git targets; guard absent worktree status and exclude
      directories, ignored entries, disabled untracked entries, unavailable
      paths, and paths outside `state.path`.
- [x] 3.2 Build navigation items and ancestors with real types using existing
      filesystem item helpers; ensure a selected directory without changed
      descendants remains a directory. Reproduce `a-empty` -> `b/file.txt`
      instead of `z.txt`.
- [x] 3.3 Route navigation item sorting through `file_items.advanced_sort` with
      the current state, supplying metadata required by field sorting; stop
      using the independent name-only `sort_by_tree_display` for this command.
- [x] 3.4 Select targets by depth-first traversal of sorted items; reverse the
      same order for `[g]` and wrap only among eligible changed leaves. Verify a
      clean anchor never becomes a wrap target.
- [x] 3.5 Return without focus/navigation calls when no eligible target exists;
      retain `renderer.focus_node` for loaded targets and `fs.navigate` for
      unloaded targets.

## 4. Focused verification

- [x] 4.1 Verify exact forward/reverse sequences for `a/deep/one.txt`,
      `a/two.txt`, `z.txt`, starting from each leaf, a clean file, and
      `a-empty`; include wraparound and a single changed leaf.
- [x] 4.2 Compare navigation against display ordering for case-insensitive
      names, a custom comparator, and a state field/direction sort override.
- [x] 4.3 Verify root-level untracked files and nested untracked folders with
      the option enabled/disabled, initially collapsed and previously loaded
      then collapsed; confirm reveal reaches the file.
- [x] 4.4 Verify nil/empty status, ignored-only and unavailable-only targets,
      and a tree rooted below the repository root produce safe, scoped results.
- [x] 4.5 Exercise real `]g`/`[g` after the initial full async scan and after
      refresh in a disposable repository; record sequences and checks in
      `verification.md`, inspect the plugin/config diff, and validate OpenSpec.

## 5. Active keymap integration discovered during implementation

- [x] 5.1 Trace the after-render navigation wrapper and identify its plain-path sort as a bypass of plugin ordering.
- [x] 5.2 Delegate filesystem non-conflict navigation to the fixed plugin commands while preserving layout-aware mappings and repeat navigation.
- [x] 5.3 Exercise the actual wrapper with forward/reverse keypresses and verify repeat-navigation registration.

## 6. Submodule follow-up

- [x] 6.1 Preserve existing tree ordering; discard the interrupted lexicographic experiment.
- [x] 6.2 Accept directory paths with direct tracked Git status (gitlinks), while excluding table-valued parent bubbles and untracked directory summaries.
- [x] 6.3 Verify real submodules with changed checkout, staged pin, clean state, and tracked dirtiness, plus actual forward/reverse keypresses into and past a submodule.
