# Verification

## Baseline and reproduction

All four focused MiniDiff suites passed before implementation. A new fixture
staged a twelve-line whole-file addition and changed line 5 without restaging.
Before the fix, the expected ranges `1–4`, `5`, and `6–12` collapsed to `1–12`.

## Implementation

`navigation/global_navigation.lua` now normalizes each layer separately and
subtracts effective unstaged ranges from projected staged ranges. Returned
segments retain `from`/`to` plus layer identity. Source hunks remain unchanged.

`rendering.lua` preserves existing unstaged extmark options on overlapping lines
and paints staged markers only where no unstaged marker exists. The existing
`MiniDiffViz` statuscolumn integration needs no configuration changes.

## Passing checks

```sh
nvim --headless -u NONE -l tests/minidiff_staged.lua
nvim --headless -u NONE -l tests/minidiff_layers.lua
nvim --headless -u NONE -l tests/minidiff_pipeline.lua
nvim --headless -u NONE -l tests/minidiff_feedback.lua
git diff --check
```

The extended staged suite checks exact coordinates for a contained replacement,
multiple edits, insertion above and inside the staged addition, interior and
start-of-file deletion anchors, complete overlap, an empty buffer, and return to
staged-only state. It also checks saved/unsaved edits without changed locations,
actual unstaged sign glyphs/highlights, staged remainder signs, and overlay
toggle preservation.

Mapping/repeat integration checks forward/backward adjacent stops, backward
wrapping, lualine position/counts, and handoff only after the final segment.
Action checks prove staged-only refusal, exact contained-hunk preview and
selection, selective unstaged reset, and unchanged Git index/staged snapshot.

Pure segment cases additionally cover same-layer contiguous grouping, an
unstaged range spanning multiple staged ranges, coincident zero-line deletion
anchors, adjacent different-layer ranges, empty layers, and source immutability.
Existing pipeline checks still prove saved/unsaved cancellation creates no
marker, stop, or count, along with source lifecycle and preview protection.

## Remaining manual check

The light/dark theme statuscolumn appearance has not been visually inspected.
The automatic checks verify `MiniDiffViz` sign glyphs/highlight identities and
overlay on/off behavior, not perceived theme contrast in an interactive UI.
