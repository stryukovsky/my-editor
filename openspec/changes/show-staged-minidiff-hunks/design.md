# Design

## Existing seams

- `moonshine.nvim/mini_diff/lua/mini/diff.lua` owns the Git index reference,
  buffer diff calculation, gutter rendering, attachment lifecycle, and request
  invalidation.
- `moonshine.nvim/diff_tools/lua/moonshine/diff/init.lua` owns navigation,
  end-of-file handoff, action wrappers, and the hunk statusline component.
- `moonshine.nvim/diff_tools/lua/moonshine/diff/assure_git_hunks_are_ready.lua`
  currently rejects navigation when the unstaged summary is empty. That is
  incorrect for a staged-only file.
- `lua/mappings/minidiff.lua` already provides `]g`, `[g`, and shared navigation
  repeat. No new mapping is needed.
- `lua/configs/statuscolumn.lua` explicitly renders `MiniDiffViz` signs and
  routes gutter clicks to preview/reset. `lua/highlight.lua` owns theme-safe
  overrides.
- `tests/minidiff_feedback.lua` provides headless regression patterns despite
  the older repository guide's statement that there are no tests.

The existing `improve-minidiff-progress-feedback` change explicitly deferred
staged diffs. This proposal is that follow-up; it does not rewrite its artifacts
or relax its lifecycle guarantees.

## Two independent comparisons

Keep the current index → buffer comparison and its public hunk/summary contract
intact. Add an additive staged snapshot for HEAD → index with its own readiness
and request identity. Never replace the normal index reference with HEAD: HEAD →
buffer would conflate the two layers and can hide staged changes that were
reversed locally.

Compute staged hunks in index coordinates and retain their original ranges.
Expose projected buffer ranges separately for display and navigation. Reuse
existing scheduling and Git attachment infrastructure rather than adding a
second plugin or polling loop.

Use `git diff --cached` as the authoritative HEAD → index snapshot and parse
zero-context hunk headers. This avoids loading full HEAD text solely to compute
staged ranges and naturally handles unborn HEAD. Read the normal index reference
in the same request generation and wait for both callbacks before publishing the
combined display update. Each layer retains its own readiness.

Detect index changes and HEAD/ref changes, including commits and branch switches
that leave index contents identical. Watch the resolved Git directory, HEAD
reflog, and symbolic HEAD target directory. Read the worktree's `commondir` when
present so branch refs and packed refs are watched in the shared repository.
Revalidate on buffer entry and focus gain. No polling loop is added.

A missing HEAD in an unborn repository is an empty baseline. A path absent from
HEAD can represent a staged addition. Do not treat arbitrary Git failures or
unmerged entries as an empty baseline. On failure, clear stale staged
presentation and retain truthful staged readiness without blocking unrelated
ready unstaged actions.

## Mapping staged ranges

Use the existing index → buffer edit script to map staged index ranges into
current buffer coordinates. Account for insertions, replacements, and deletions;
clamp deletion or fully removed spans to a valid buffer-line anchor. Reproject
on buffer edits, including unsaved edits, without rereading HEAD unnecessarily.

Do not derive staged hunks from HEAD → buffer. Keep a staged change visible even
when a later unstaged edit reverses it. Projection is a display anchor, not an
exact representation of staged text when that text no longer exists in the
buffer.

## Presentation and navigation

Use the existing gutter footprint with distinct staged and unstaged marker
styles, plus a mixed style where both occupy a line. Preserve add/change/delete
meaning through highlight groups. Integrate with the explicit statuscolumn
namespace filter and theme overrides; avoid adding a permanently reserved gutter
column.

Build an ordered union of contiguous hunk ranges in buffer coordinates. Merge
overlapping targets into one stop carrying both layer identities. Adjacent
ranges follow the existing contiguous-range grouping rule. The statusline
position/count uses that same target list rather than the unstaged summary.

Use the combined list only in ordinary Git-backed buffers. Preserve native diff
navigation and existing review/history comparisons. Preserve backward wrapping
and navigation repeat. Apply the existing forward Neo-tree handoff after the
final combined target.

Combined navigation must not silently skip staged targets while their current
snapshot is pending or failed. Explain that state without replaying the action
later. Ready unstaged reset/preview/selection continue to use unstaged readiness
and data independently.

## Mutation boundaries

Do not pass staged ranges to `MiniDiff.do_hunks`, unstaged textobjects, or the
existing preview renderer. On a staged-only target, these actions give concise
feedback and perform no operation. At a mixed target, they operate only on an
applicable unstaged hunk under the cursor. Inline overlays remain unstaged-only.

Gutter click handling must preserve this boundary, especially middle-click
reset. Resetting an unstaged edit remains a buffer operation and never changes
the Git index.

## Verification

Use temporary Git repositories and headless Neovim checks for staged-only files,
partly staged files, overlap, reverse edits, unsaved line shifts, deletion
anchors, unborn HEAD, reference refresh, and obsolete callbacks. Verify existing
feedback regression checks still pass. Exercise repeat, statusline counts,
final-target handoff, and action guards through the Moonshine integration.
Manually check marker distinction under both themes and ensure review/native
diff navigation remains unchanged.
