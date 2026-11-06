## Code findings

### Untracked candidates: collection, not the status predicate

`lua/configs/neotree.lua:107-117` already installs a `before_git_status`
handler that rewrites `--untracked-files=normal` to `all`, preserving `no`.
Line 128 also enables `consider_untracked_as_git_change`. The previous design
missed this existing workaround. With that handler active and a completed scan,
ordinary untracked files should already be candidates; the reported omission
cannot be attributed to the plugin default alone in this configured session.

In the plugin, `git/init.lua:207` defaults status collection to `normal`.
`status_async` uses `no` for the first fast scan, `normal` for subsequent scans
(line 420), and the same default for the first full scan (line 497). A later
refresh replaces `worktree.status`, rather than retaining previously discovered
untracked leaves. Fixing only the initial full scan would therefore regress on
refresh. The `status.showUntrackedFiles=no` branch also skips initial untracked
collection; navigation currently does not check scan readiness.

A disposable Git repository confirmed `normal` reports `? new/`, while `all`
reports `? new/deep/two.txt` and `? new/one.txt`, excluding an ignored `.log`.
`git/parser.lua:255-259` preserves the returned path and assigns scalar `?`.
The parser does not enumerate a directory's children. Navigation in
`sources/filesystem/commands.lua:165-174` accepts scalar `?` when enabled, but
its `fs_stat` predicate at lines 180-184 rejects directories. Thus collapsed
Git directory records cannot become navigation targets.

### Ordering: independent sorters, not a breadth-first walk

`utils.sort_by_tree_display` (utils/init.lua:1146-1210) builds a synthetic tree,
classifies directories using `#children > 0`, sorts siblings by case-sensitive
name, and walks depth-first. A headless invocation returned
`a/deep/one.txt`, `a/two.txt`, `z.txt`: the basic nested-first case already works.
There is no global shallower-path priority in this code.

The displayed filesystem uses `sources/common/file-items.lua:7-101` instead:
actual item types, configured `sort_function`, `sort_case_insensitive`, and
state sort overrides/field providers. Navigation ignores these settings.
A headless comparison with case-insensitive sorting returned display order
`a.txt, Z.txt` but navigation order `Z.txt, a.txt`.

The synthetic tree also misclassifies a selected directory with no candidate
children. For current directory `a-empty` and changed files `b/file.txt` and
`z.txt`, the helper returns `b/file.txt, a-empty, z.txt`. In the default display,
`a-empty` precedes `b`; next-change should enter `b`, but the current algorithm
skips it and selects the shallower `z.txt`. This is a concrete mechanism for
apparent shallow-file preference when starting from a directory. It does not
establish every instance of the reported ordering symptom.

### Anchor and target are incorrectly mixed

`commands.lua:164` inserts the current path into the candidate list even if
clean. The selection loop at lines 187-207 tests only filesystem existence/type,
so that clean file can become the wraparound target. The anchor needs an order
position but must not become an eligible target. `pairs(worktree_info.status)`
also assumes status exists. When no eligible target is found, `get_node(nil)`
can resolve to the current node, after which `focus_node(state, nil)` returns
false; explicit no-op handling is clearer and avoids depending on this behavior.

### Reveal already supports collapsed ancestors

`renderer.focus_node` (ui/renderer.lua:503-540) expands ancestors when an existing
node has no visible line. For unloaded targets, `fs.navigate` passes the reveal
path to `fs_scan.get_items` (sources/filesystem/init.lua:156-159). Preserve these
paths: missing Git candidates are not evidence of a reveal implementation bug.

### Active mapping bypass discovered during implementation

`lua/mappings/neotree_git_navigation.lua` is attached after every render and
replaces `]g`/`[g`. Its filesystem branch uses `table.sort(ids)` on full paths,
not the plugin tree sorter. Thus the active keys bypassed the plugin command
examined above. For example `a.txt` sorts before `b/file.txt`, although the
filesystem displays directory `b` first. This explains the reported shallow-file
preference for that layout. Route filesystem non-conflict navigation through the
plugin's `next_git_modified`/`prev_git_modified` while retaining the wrapper's
layout-aware mappings and repeat-navigation registration. Git-status source and
conflict navigation keep their existing behavior.

## Implementation decisions

1. Move the existing `normal` to `all` policy into the plugin status command
   builder when untracked navigation is enabled. Preserve explicit `no` for the
   fast scan and preserve the disabled setting. This covers synchronous scans,
   initial full asynchronous scans, and subsequent asynchronous refreshes.
   Remove only the now-redundant config event handler after verification.
2. Keep navigation safe while the first scan is absent/incomplete. Preserve the
   current Git `status.showUntrackedFiles=no` policy in this change; inclusion
   checks assume Git allows untracked collection and the full scan has finished.
3. Construct ordered items with real directory/file types and ancestor links,
   using the same sorting entry point as filesystem display
   (`file_items.advanced_sort`). Supply metadata needed by supported field-based
   sorting and custom comparators, using existing file-item construction helpers.
   Keep current selection as an anchor, separate from eligible changed leaves.
4. Walk the sorted items depth-first, select the next/previous eligible leaf,
   and wrap only over eligible leaves. Skip unavailable paths and out-of-root
   entries. Return early for missing status or an empty target set.
5. Reuse existing focus/reveal behavior. Do not add keymaps, replace commands in
   the config, or change Git-status source grouping.

## Scope and verification

Implementation belongs in `/home/dmitry/.config/nvim/data/lazy/neo-tree.nvim`;
OpenSpec remains here. Do not manually edit `lazy-lock.json`. Config integration removes the migrated event workaround and delegates the
existing filesystem Git-change wrapper to the plugin commands.

Use focused plugin checks and a disposable repository, not a new config test
suite. Verify each collection path and the precise ordering/anchor examples
above, then actual `]g`/`[g` with collapsed folders. Record any remaining reported
ordering behavior separately rather than claiming the existing traversal is
breadth-first. Enumerating all untracked files increases scan output; retain the
fast tracked-only phase and existing asynchronous batching.

## Submodule follow-up

The user retained tree ordering and requested only submodule inclusion. The
filesystem predicate rejected every directory, including a changed gitlink.
The existing Git parser distinguishes direct entries (string status codes) from
parent-directory bubbles (table status codes). Navigation now admits tracked
directory entries reported directly by Git while continuing to reject ordinary
bubbles and untracked directory summaries. It keeps the existing item type for
sorting/reveal and treats the submodule path as an eligible target. No extra Git
process or filesystem `.git` heuristic is needed.
