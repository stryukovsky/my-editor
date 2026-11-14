# Consolidate the MiniDiff hunk pipeline

## Why

The local MiniDiff engine and its Moonshine integration currently live in two
plugin directories, with fetching, mutable snapshots, and navigation mixed
across them. Consolidating ownership under `mini_diff` will make each hunk kind
easier to inspect without requiring users to think about its source.

## Changes

- Merge `moonshine.nvim/diff_tools/` into `moonshine.nvim/mini_diff/` and remove
  the old plugin root after moving its contents and updating references.
- Introduce `hunks_loader/`, `hunks_cache/`, and `navigation/` beneath
  `mini_diff/lua/mini/diff/`.
- Give each directory explicit `staged.lua`, `unsaved.lua`, `untracked.lua`, and
  `unstaged.lua` modules with real responsibilities.
- Keep session-local hunk storage and its management APIs in `hunks_cache/`,
  rather than maintaining authoritative snapshots inside loaders, renderers, or
  navigation.
- Route existing hunk movement and position/count presentation through
  `navigation/global_navigation.lua`.
- Extract `rendering.lua`, `preview.lua`, and `hunk_mode.lua` so drawing,
  preview windows, and the existing overlay toggle have separate owners.
- Preserve existing user behavior, including current net index → buffer
  semantics for nonstaged changes, keybindings, markers, action safety, and
  review/history behavior.
- Keep the existing `mini.diff` and `moonshine.diff` module entry points
  available from the single remaining plugin root.

## Acceptance

- The `diff_tools` plugin directory is gone. All of its runtime modules load
  from `mini_diff` alone, without a forwarding plugin at the old location.
- Each loader/cache/navigation directory contains all four named kind modules.
  Acquisition, session storage, and navigation rules are owned by their
  respective directories.
- Rendering owns gutter/inline drawing and decoration cleanup. Preview owns
  preview-buffer construction and lifecycle. Hunk mode owns the existing global
  overlay preference and synchronization across buffers.
- Toggling hunk mode off hides inline overlays without disabling gutter markers,
  loading, navigation, or cached hunks. Turning it back on and
  updating/switching buffers retains the current global preference behavior.
- Preview buffers retain their existing content, word highlights, read-only
  protection, lifecycle, and staged-only feedback through the new preview
  module.
- `hunks_cache` exposes snapshot retrieval, publication, invalidation, and
  cleanup without exposing mutable authoritative tables to consumers.
- A changed buffer cannot accept results belonging to an obsolete attachment,
  path, reference request, or saved-file revision.
- Staged, saved unstaged, unsaved, and untracked changes remain reachable
  through the existing navigation controls without selecting a hunk kind.
- Saved and unsaved edits that cancel each other produce no additional nonstaged
  navigation target. This preserves the explicitly selected current behavior.
- Overlaps and adjacent ranges retain current grouping, ordering, repeat,
  backward wrapping, statusline counts, and final-target handoff.
- Navigation settles pending local computation before moving, but never acts on
  pending Git results or replays a blocked jump later.
- Existing preview, reset, selection, overlay, native diff navigation, review,
  and history protections remain unchanged. Navigation ranges never become
  mutation ranges.
- All three existing headless diff suites pass using only the `mini_diff` plugin
  runtime path. New focused checks prove kind ownership, cache isolation,
  invalidation, and cancellation behavior.

## Out of scope

- Making saved unstaged and unsaved edits independently navigable when their net
  effect cancels.
- New mappings, hunk-kind filters, marker styles, staged mutation actions, or
  staged previews.
- Changing the comparison semantics of review/history buffers or manual/save
  sources.
- Persisting caches, sharing them across Neovim processes, or scanning every
  repository file.
- A generic provider registry, new dependencies, or rendering behavior changes
  beyond the requested ownership split.
