# Tasks

## 1. Engine lifecycle and regression proof

- [x] 1.1 Add the read-only buffer state snapshot and state-change event to the
      local MiniDiff engine, document the additive contract alongside its public
      APIs, and add `tests/minidiff_feedback.lua`; verify initial loading,
      scheduled updating, ready hunks, and ready zero-hunk transitions with
      `nvim --headless -u NONE -l tests/minidiff_feedback.lua`.
- [x] 1.2 Instrument Git attachment/reference acquisition, nil-reference
      results, source fallback, spawn errors, computation errors, disable, and
      teardown; extend the same headless test to prove every terminal path
      clears busy state and manual reference sources recover normally.
- [x] 1.3 Protect reference callbacks with attachment identity and request
      tokens, accounting for simultaneous pending buffer updates; verify
      controlled out-of-order completions cannot replace newer results, mark
      newer work ready, or re-enable a disabled/reloaded buffer.

## 2. Action feedback and statusline

- [x] 2.1 Add the shared `moonshine.diff.feedback` guard and use it in
      navigation, direct hunk preview, selection, and reset; add headless checks
      that pending/unavailable/failed actions report their actual state, do not
      modify content, do not replay later, and distinguish ready zero hunks from
      no cursor hunk.
- [x] 2.2 Reuse buffer-scoped `integrations.notify.replace` keys and surface
      operation failures without unsolicited transition toasts; stub
      notifications in the headless test to verify repeated actions share a key
      and different buffers do not collide.
- [x] 2.3 Extend the existing `lualine_hunks` component with static
      loading/updating labels and refresh on state changes; test buffer
      switching, completion, and side-effect-free rendering, and document the
      synchronous-computation visibility limitation near the implementation.
- [x] 2.4 Extend regression checks for native diff-window navigation, review
      reset protection, ready hunk actions, global overlay preference, and
      existing end-of-list behavior; verify all cases pass without adding
      mappings or staged-diff behavior.

## 3. Integration verification

- [x] 3.1 Run `nvim --headless -u NONE -l tests/minidiff_feedback.lua` and
      targeted formatting/syntax checks for changed Lua files; verify
      `git diff --check` passes and record exact results.
- [x] 3.2 Smoke-test a tracked file with hunks, a clean file, an unavailable
      reference, and an artificially delayed reference load in the configured
      Neovim UI; verify the displayed buffer's progress clears correctly, action
      messages replace rather than stack, and ready-state navigation/preview
      still work.
