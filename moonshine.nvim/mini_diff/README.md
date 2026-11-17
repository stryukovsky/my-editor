# MiniDiff ownership

This single local plugin provides both `mini.diff` and `moonshine.diff`, including
review/history integration. The former `diff_tools` runtime root is no longer used.

## Pipeline

- `lua/mini/diff/hunks_loader/`: staged Git patches, index acquisition, new-path
  classification, saved-file reads, and live-buffer comparisons. `init.lua`
  coordinates shared reference generations and saved baselines.
- `lua/mini/diff/hunks_cache/`: independent session-local stores for staged,
  unstaged, unsaved, and untracked data. Kind modules expose `get`, `state`,
  `begin`, `publish`, `invalidate`, and `clear`. `get` returns a copy; publication
  rejects obsolete tokens, buffer revisions, saved revisions, and renamed paths.
  `_read`/`_write` and attachment adapters are private engine plumbing, not consumer APIs.
- `lua/mini/diff/navigation/`: per-kind projection/eligibility rules and
  `global_navigation.lua` for layer-aware segmentation, position/counts, movement, repeat entry
  points, and final-target handoff.
- `lua/mini/diff/rendering.lua`: gutter/inline decorations, word highlights,
  preview painting, redraws, and decoration cleanup. It owns derived drawing data only.
- `lua/mini/diff/preview.lua`: existing read-only hunk preview content and buffer/window lifecycle.
- `lua/mini/diff/hunk_mode.lua`: existing global inline-overlay preference and
  per-buffer synchronization. Turning overlays off does not disable loading,
  gutter markers, navigation, or caches.
- `lua/moonshine/diff/`: public integration facade, action feedback, review,
  and history. `moonshine.diff.hunks` delegates to the preview module.

## Preserved comparison rules

Staged hunks compare HEAD to the index. Ordinary nonstaged hunks still compare
the index to the live buffer. Saved changes (`saved_hunks` in the unstaged
snapshot) and raw disk-to-buffer changes (the unsaved snapshot) are available
internally, but are not blindly unioned for navigation. If they cancel, they add
no effective nonstaged target. Eligible untracked paths use an empty index baseline.

Legacy `MiniDiff` snapshot/mutation APIs use the effective comparison. Navigation
may include projected staged anchors; mutation and preview never receive those
anchors as reset/selection ranges. Review/manual sources do not run ordinary
Git or saved-file loaders.

## Overlapping staged and unstaged changes

Effective unstaged hunks take precedence over projected staged ranges for
navigation and gutter signs. Staged ranges are split around unstaged hunks;
the remaining staged-only portions are separate navigation stops, even when
directly adjacent to unstaged stops. Contiguous hunks within one layer still
group together. Counts, repeat, and end-of-file handoff use this same list.

For example, a staged whole-file addition at lines 1–20 with a later unstaged
edit at 8–9 has stops at 1–7 (staged), 8–9 (unstaged), and 10–20 (staged).
Unstaged add/change/delete signs remain visible in `MiniDiffViz`, including
deletion anchors; staged-only lines retain their staged signs. Overlap no longer
replaces an unstaged sign with a mixed marker. Inline overlays are unchanged.

These segments are derived display data only. HEAD → index hunks and effective
index → buffer hunks stay intact. Reset, preview, and selection continue using
the actual effective unstaged hunks rather than split staged segments.

## Regression checks

Run from the Neovim configuration root:

```sh
nvim --headless -u NONE -l tests/minidiff_feedback.lua
nvim --headless -u NONE -l tests/minidiff_staged.lua
nvim --headless -u NONE -l tests/minidiff_layers.lua
nvim --headless -u NONE -l tests/minidiff_pipeline.lua
```
