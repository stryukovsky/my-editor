## Context

The existing Telescope handoff transfers ripgrep results into Trouble.
Ripgrep reports matching lines and a starting byte column. Replacement needs
the byte range of every occurrence on each retained line.

## Decisions

- Use a dedicated Trouble mode for the live ripgrep handoff. Keep the
  transferred items and the effective search pattern available for that view.
- Open a Telescope picker over the current Trouble items with `f`. On Enter,
  apply a view filter using the matching results or the explicit selection.
- Prompt for replacement text once with `r`. Recover the occurrence ranges
  by running ripgrep JSON search against the captured result lines using the
  original effective pattern. Build a separate focused Trouble view with an
  inline preview for each occurrence, with unchanged text shown once.
- Preflight the selected targets against current file buffers before editing.
  Apply replacements as literal, undoable buffer edits, from later byte ranges
  to earlier ones. Refresh previews and update remaining byte offsets after
  each successful edit.
- Apply the focused occurrence with `r`. With `R`, confirm the number of
  remaining occurrences, including folded rows, with No as the default.

## Trade-offs

Search snapshots describe on-disk lines. If a target line has changed in
a buffer, preflight rejects that target. Unrelated unsaved edits are preserved.
