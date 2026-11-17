# Design

## Existing cause and integration points

`moonshine.nvim/mini_diff/lua/mini/diff/navigation/global_navigation.lua` collects effective unstaged and projected staged hunks, then calls `contiguous()`. That function discards layer identity and merges every overlapping or adjacent range. A projected staged addition spanning the entire file therefore collapses every contained unstaged hunk into the same target.

`moonshine.nvim/mini_diff/lua/mini/diff/rendering.lua` first builds unstaged signs in `H.update_hunk_data`, then `H.update_staged_viz` overwrites those entries with staged or mixed signs. `lua/configs/statuscolumn.lua` already displays the `MiniDiffViz` namespace, so this change should flow through the existing statuscolumn seam rather than introducing another sign provider.

Staged projection in `navigation/staged.lua` maps index-coordinate ranges through effective index → buffer edits. The baseline comparisons are already separate; do not replace them with HEAD → buffer or alter staged cache hunks to solve a downstream grouping problem.

Related active changes `show-staged-minidiff-hunks` and `consolidate-minidiff-hunk-pipeline` specified merged overlapping/contiguous stops and mixed markers. This proposal deliberately supersedes those particular user-visible rules while preserving their comparison, readiness, cache, and mutation boundaries. Their historical artifacts remain unchanged.

## Layer-aware segments

Use the canonical effective unstaged ranges already supplied by the pipeline, including the existing untracked eligibility and saved/unsaved reconciliation. Normalize them using existing within-layer grouping. Normalize staged display ranges separately after their existing projection.

Subtract the normalized unstaged ranges from the projected staged display ranges. Emit each nonempty staged remainder as a staged-only segment; retain every normalized unstaged range as an unstaged segment. Sort the combined list in live-buffer order. Do not run the result through the current layer-blind contiguous union.

Carry enough internal layer identity to prevent adjacent different-layer segments from merging. Keep public range consumers compatible with their existing `from`/`to` fields. Use the existing global navigation module as the owner of the final segment list rather than adding a parallel consumer cache or renderer-specific navigation algorithm.

For example, a projected staged addition covering lines 1–20 with an effective unstaged edit at 8–9 yields:

- Staged: 1–7.
- Unstaged: 8–9.
- Staged: 10–20.

The unstaged segment remains a distinct stop even though all three segments are adjacent. An unstaged insertion before the file's staged contents similarly stays separate from the shifted staged portion. Fully overlapped staged segments disappear from this derived list only; the staged snapshot remains intact.

Apply existing valid-line anchoring to zero-line deletions before range subtraction. If a staged deletion and unstaged change share the same drawable anchor, unstaged wins that anchor and no duplicate staged navigation stop is emitted. This prioritizes the actual actionable change without pretending the index no longer contains a staged change.

## Rendering precedence

Retain the existing unstaged add/change/delete extmark options on lines they occupy. Add staged markers only to staged-only positions. Use the same overlap/anchoring policy as navigation, preferably through a small shared pure range helper within the existing navigation ownership if reuse is needed. Do not copy range subtraction into multiple consumers.

No new glyphs, highlight groups, or statuscolumn columns are required. Existing mixed highlight definitions can remain for compatibility; ordinary staged/unstaged overlap no longer selects mixed signs. Existing overlay drawing stays based on effective unstaged hunks and is not broadened to staged segments.

## Safety and consumers

`global_navigation.position`, movement, lualine counts, and the Moonshine final-target handoff must all see the new list. In particular, a cursor inside the first staged portion must not trigger final-target handoff while an unstaged portion or later staged portion remains.

Presentation segments are never passed into reset, preview, selection, or patch creation. Those operations continue to resolve the original effective unstaged hunk under the cursor and retain staged-only feedback. Navigation/rendering must not mutate authoritative staged hunks, effective hunks, buffer text, or the index.

## Verification

Extend the existing staged and layered regression checks with temporary Git repositories. Cover a staged whole-file addition followed by edits near the beginning and middle, multiple contained edits, insertion above a staged range, complete overlap, and deletion anchors. Assert exact segment coordinates and `MiniDiffViz` sign glyph/highlight options rather than hunk count alone.

Update the old overlap assertions that intentionally require mixed markers or layer-blind merging. Preserve tests for within-layer contiguous grouping, saved/unsaved cancellation, staged-only actions, reference refresh, stale publication, and native/review navigation. Verify forward/backward movement, repeat, lualine position/counts, and delayed final-target handoff through the existing integration tests.

Run the focused suites documented in `moonshine.nvim/mini_diff/README.md`: `tests/minidiff_staged.lua`, `tests/minidiff_layers.lua`, `tests/minidiff_pipeline.lua`, and `tests/minidiff_feedback.lua`. Manually verify the statuscolumn under both themes with inline overlays enabled and disabled.
