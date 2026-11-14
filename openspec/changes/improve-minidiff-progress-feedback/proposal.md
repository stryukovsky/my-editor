# Proposal

## Why

MiniDiff actions currently conflate missing diff data with an empty diff:
navigation can silently return and preview can report “No hunk under cursor”
before reference loading finishes. Buffer-local progress and precise action
feedback will make pending computation distinguishable from a completed, clean
diff.

## What Changes

- Expose actual buffer-local reference-loading and diff-update lifecycle state.
- Display a compact statusline indicator while initial loading or a subsequent
  update is pending; preserve the existing ready-state hunk display.
- Give consistent, replaceable notifications when navigation, preview,
  selection, or reset cannot proceed because data is pending, unavailable,
  failed, or has no applicable hunks.
- Clear progress on completion, failure, disable, and buffer teardown; ignore
  obsolete asynchronous completions.
- Non-goals: staged diff (explicitly deferred), dirty-buffer indicators, new
  keybindings, asynchronous diff execution, progress percentages, and changes to
  review/reset semantics.

## Capabilities

### New Capabilities

- `buffer-diff-feedback`: Truthful per-buffer diff readiness, progress
  presentation, and action feedback.

### Modified Capabilities

None.

## Impact

- Local MiniDiff implementation: `moonshine.nvim/mini_diff/lua/mini/diff.lua`
  owns lifecycle signals around attachment, Git reference reads, scheduling,
  computation, and cleanup.
- `moonshine.nvim/diff_tools/lua/moonshine/diff/` consumes state for action
  guards, notifications, and the existing lualine component.
- Reuses `lua/integrations/notify.lua` and the existing lualine registration; no
  new dependencies or default mappings.
- Adds focused headless regression checks under `tests/`.
