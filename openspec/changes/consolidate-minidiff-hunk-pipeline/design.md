# Design

## Confirmed behavior boundary

The user selected **preserve current behavior**, not independent navigation of
saved and unsaved layers.

Current ordinary nonstaged hunks compare the index with the live buffer. They
include saved unstaged edits and unsaved edits as one net change. Staged hunks
separately compare HEAD with the index and are projected into live-buffer
coordinates. A new internal separation must not silently replace that behavior
with a union of index → disk and disk → buffer hunks.

For example, if a saved file changes `old` to `new` and the unsaved buffer
changes it back to `old`, there is no net nonstaged hunk against an index
containing `old`. Separate raw caches may record both edits, but navigation,
markers, and hunk counts must not invent two targets—or one target—for that
cancellation. An independently staged change at that location remains visible as
before.

## Existing ownership

- `moonshine.nvim/mini_diff/lua/mini/diff.lua` currently owns the public engine,
  source lifecycle, Git reads/watchers, mutable buffer and staged caches,
  projection, rendering, and navigation primitives.
- `moonshine.nvim/mini_diff/lua/mini/diff/staged.lua` contains staged patch
  parsing and pure coordinate projection.
- `moonshine.nvim/diff_tools/lua/moonshine/diff/` owns the Moonshine facade,
  readiness feedback, hunk previews, review sessions, and history UI.
- `lua/plugins/moonshine.lua` automatically registers every local plugin root
  containing `lua/`. Moving the modules removes the extra plugin registration
  without editing `lazy-lock.json`.
- Config, mappings, lualine, statuscolumn, Trouble, and position-yank consumers
  already use the `mini.diff` or `moonshine.diff` namespaces. These imports need
  not be renamed.
- The existing regression suites are `tests/minidiff_feedback.lua`,
  `tests/minidiff_staged.lua`, and `tests/minidiff_layers.lua`. Their
  runtime-path setup and private-engine seams must follow the ownership move
  without dropping regression assertions.

Related active changes are `show-staged-minidiff-hunks` and
`improve-minidiff-progress-feedback`. Their implemented behavior is the
preservation baseline; this proposal does not replace their artifacts. The main
`git-action-scheduling` and `git-picker-actions` specifications remain unchanged
because this work neither introduces Git mutations nor changes picker actions.

## Target layout

```text
moonshine.nvim/mini_diff/
└── lua/
    ├── mini/
    │   ├── diff.lua
    │   └── diff/
    │       ├── rendering.lua
    │       ├── preview.lua
    │       ├── hunk_mode.lua
    │       ├── hunks_loader/
    │       │   ├── init.lua
    │       │   ├── staged.lua
    │       │   ├── unsaved.lua
    │       │   ├── untracked.lua
    │       │   └── unstaged.lua
    │       ├── hunks_cache/
    │       │   ├── init.lua
    │       │   ├── staged.lua
    │       │   ├── unsaved.lua
    │       │   ├── untracked.lua
    │       │   └── unstaged.lua
    │       └── navigation/
    │           ├── staged.lua
    │           ├── unsaved.lua
    │           ├── untracked.lua
    │           ├── unstaged.lua
    │           └── global_navigation.lua
    └── moonshine/
        └── diff/
            ├── init.lua
            ├── assure_git_hunks_are_ready.lua
            ├── hunks.lua
            ├── review.lua
            └── history.lua
```

The diagram shows the requested ownership split, not a prohibition on retaining
focused internal helpers. Move the existing staged parser/projection logic to
its owning layer and update repository imports rather than keeping competing
implementations. Retain the public facades, not an otherwise unused
compatibility plugin directory. `moonshine.diff.hunks` remains a compatibility
entry point forwarding its existing public preview/setup operations, not a
second preview implementation.

## Loaders: acquire and compute

`hunks_loader` owns acquisition and computation, not authoritative session
storage or cursor movement.

- `staged.lua`: Acquire HEAD → index data, preserve original index-coordinate
  hunks, and handle unborn HEAD and staged deletions without fabricating empty
  baselines after arbitrary errors.
- `unstaged.lua`: Acquire the index and saved working-tree text for tracked
  paths. Compute raw saved-change information and the canonical effective index
  → live-buffer comparison used by existing consumers.
- `unsaved.lua`: Read live buffer text/revision and compute saved-file → buffer
  changes. Coordinate with the canonical effective comparison rather than
  treating every raw unsaved edit as a new navigation target.
- `untracked.lua`: Confirm absence from the index and exclusion from ignore
  rules before establishing the empty baseline for a new file, including named
  buffers not yet written to disk. Distinguish unmerged entries and read
  failures.

The loader coordinator shares a saved-file read between tracked loaders for the
same refresh. A missing saved file is not automatically an empty file:
distinguish a new named buffer, a staged deletion, an unavailable path, and a
read failure. Reuse existing Git process settlement and watcher handling rather
than creating four watcher stacks.

Buffer edits recompute unsaved/effective data and staged projections without
rereading Git unnecessarily. Writes refresh the saved baseline and redistribute
internal provenance without changing effective navigation locations when the
buffer text is unchanged. Current Git index/HEAD/ref watchers and focus
revalidation remain in place. Ordinary buffer switches must not reintroduce
redundant loading cycles.

## Caches: one authoritative session store

Use module-local Lua state loaded once by `require`, not `_G`, persisted files,
or duplicate consumer caches. Each named kind module owns its entries.
`hunks_cache/init.lua` coordinates shared lifecycle management and common
publication checks; it does not add a dynamic provider registry.

Snapshots carry the applicable buffer/attachment identity, normalized
repository/path context, reference request generation, saved-file revision,
buffer changedtick, readiness/reason, and original/projected hunk data. Keep
only the identities relevant to each kind. A projected staged result must
identify the index and live-buffer revisions used to produce its anchors.

Expose bounded operations to read snapshots, publish current results, invalidate
affected kinds, and clear an attachment/buffer. Read methods return copies or
explicitly immutable snapshots. Provide cheap readiness/count reads for the
statusline so rendering does not deep-copy full text or hunk arrays.

`unstaged` owns the derived effective index → buffer snapshot needed by the
compatibility APIs. That derived snapshot is not a second mutable copy
maintained by `mini.diff.lua`. Shared immutable text snapshots may be referenced
by more than one kind; consumers must not independently mutate them.

Publish related data coherently. A successful staged read cannot expose ready
anchors before projection, erase an index-read failure, or adopt a
saved-file/buffer revision from another generation. Rename, source replacement,
disable, and teardown invalidate outstanding work. Empty ready results stay
distinct from unavailable/failed results.

Engine attachment configuration, watcher handles, and rendering bookkeeping may
remain outside `hunks_cache`; authoritative hunk arrays and readiness may not.
Review/manual-source snapshots must remain supported through the same cache
boundary without running ordinary Git/disk loaders against synthetic review
buffers.

## Navigation: kind rules plus one user-facing flow

Each kind module owns its relevant projection, eligibility, or source-specific
range rules. `global_navigation.lua` owns the final buffer-ordered range set and
movement policy. Per-kind modules must contain real kind-specific behavior
rather than four identical cursor-moving wrappers.

- `staged.lua` projects index-coordinate hunks through the current effective
  index → buffer edits and provides valid deletion anchors.
- `unstaged.lua` supplies canonical effective nonstaged targets for tracked
  buffers, preserving current grouping.
- `unsaved.lua` reconciles current-buffer revisions and identifies the unsaved
  contribution within those effective targets. It never independently
  contributes a raw disk → buffer range that disappeared from the effective
  comparison.
- `untracked.lua` supplies whole-buffer addition ranges for eligible new paths
  without also registering the same file as an ordinary tracked addition.

The global layer uses the canonical effective nonstaged list, staged
projections, and applicable untracked results—not a blind union of all raw
caches. Preserve kind provenance internally where needed, but count an
overlapping/contiguous target only once. No user-facing kind selector is added.

Forward/backward navigation, existing repeat callbacks, optional counts,
readiness checks, local debounce settling, jumplist/fold handling, current-range
reporting, statusline counts, and end-of-list handoff must agree on this same
target set. Preserve the current last-target Neo-tree/review-list handoff and
backward wrapping. Native diff windows continue to bypass ordinary hunk
readiness.

## Rendering, preview, and hunk mode

These are three shared behavior modules, not another four-way split by hunk
kind. They consume the canonical snapshots and current action rules; they do not
fetch references or maintain competing hunk caches.

### `rendering.lua`

Own the existing decoration provider, gutter/extmark generation, staged/mixed
markers, inline overlay drawing, word-level highlight painting, redraw requests,
and decoration cleanup. Keep renderer-owned state limited to derived draw data,
namespaces, and display bookkeeping. Cache publication and hunk readiness remain
in `hunks_cache`; coordinate projection remains in the appropriate navigation
module.

Rendering must preserve existing glyphs, highlight group names, priorities,
visible-window behavior, and statuscolumn compatibility. Preview-specific
painting may reuse focused rendering helpers, but opening a preview must not
register another live-buffer decoration provider or modify the source buffer's
display preference.

### `preview.lua`

Move the current implementation in `moonshine.diff.hunks` here: locating an
applicable effective nonstaged hunk, building its old/new content, creating the
preview buffer/window, applying its existing layout/highlights, enforcing
read-only and no-save behavior, and handling preview cleanup/setup. Reuse
`rendering` for drawing helpers where that prevents duplicate implementations
without mixing preview lifecycle into the renderer.

Existing facade calls, gutter clicks, and `<leader>gh` delegate to this module.
Preserve readiness feedback, staged-only refusal, preview re-entry protection,
existing buffer/window behavior, and setup idempotence. This extraction does not
introduce staged previews or change what a preview represents.

### `hunk_mode.lua`

For this refactor, **hunk mode means the current inline-overlay toggle**
controlled by `<A-h>` and `vim.g.minidiff_overlay`. It does not mean
enabling/disabling MiniDiff attachment or introducing a new mode.

Own reading/changing the global requested overlay preference, applying it to
enabled buffers, synchronizing it after `MiniDiffUpdated`, and the existing
toggle notification. Retain `MiniDiff.toggle_overlay(buf)` as the compatible
per-buffer operation and `moonshine.diff.toggle_overlay()` as the global facade
operation, with policy delegated rather than duplicated.

Turning the mode off clears inline overlay decorations while leaving gutter
signs, source loading, cache contents, and navigation active. A subsequently
enabled/updated buffer adopts the current preference. Repeated setup cannot
duplicate synchronization autocmds. Preview buffers remain excluded by their
existing disable/protection rules. Do not implicitly attach disabled buffers,
replay actions, or reload Git references solely to change presentation.

The dependency direction is facade → mode/preview → rendering and snapshot
reads. Rendering never calls back into mode to change policy, and none of these
modules owns authoritative hunk data.

## Public compatibility and safety

Keep `require("mini.diff")`, `require("moonshine.diff")`, their current consumer
entry points, buffer variables, highlight groups, and User-event behavior
available from the merged plugin. Where callers previously read legacy engine
fields, make those APIs adapters over the authoritative caches rather than
maintaining old and new stores in parallel.

Reset, preview, selection, and overlays continue using the existing effective
nonstaged comparison. They do not receive projected staged navigation ranges or
raw saved-file hunks. Existing staged-only feedback and review reset protection
remain unchanged. No fetch, navigation, cache refresh, or plugin move may
implicitly write a buffer or modify Git state.

## Verification and sequencing

First record the current three-suite baseline. Move the plugin modules and prove
they load with only the merged runtime root before changing internal ownership.
Extract loader/cache ownership next, then route navigation and consumers through
the new layer. Extract rendering, preview, and mode ownership with the existing
public facade calls intact.

After each ownership move, run the nearest regression suite. Add explicit
saved/unsaved cancellation tests, save-without-target-change tests, per-kind
cache isolation, stale saved-file/index/buffer generation tests, and
duplicate-target checks. Preserve the existing coverage for untracked/ignored
files, unborn HEAD, worktrees, reverse edits, projection, callback ordering,
debounce settling, and mutation safety. Verify marker and overlay extmarks
before/after toggling, global preference propagation, preview
protection/cleanup, and repeated-setup idempotence. Check the configured
light/dark rendering manually without changing its appearance.

Update runtime-path references in tests and project documentation. Do not remove
the old plugin root until all its runtime modules have moved and callers no
longer rely on that path. Stop when the single-root pipeline passes the
preservation checks; do not use the refactor to add new hunk behaviors.
