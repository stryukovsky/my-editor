# Design

## Context

See `proposal.md` for motivation and `specs/persistent-marks/spec.md` for
behavior. `chentoast/marks.nvim` currently owns `m`, `]m`, `[m`, `dm`, and
`<leader>dm` via `lua/configs/marks.lua`. `lua/configs/statuscolumn.lua` renders
diff signs separately from other signs. Local plugins under
`moonshine.nvim/*/lua/` are auto-registered, while setup and keymaps live in
`lua/configs/` and `lua/mappings/`. `moonshine.utils.navigation_repeat` already
powers `;` and (outside macros) `n`; `]]`/`[[` have no explicit mappings. The
configured data directory is patched to `~/.config/nvim/data/`.

## Goals / Non-Goals

**Goals:**

- Keep the mark store independent of buffer lifetimes and keep cursor positions
  accurate during in-memory edits.
- Preserve native non-lowercase mark motions and the existing status-column
  layout/signs.
- Make navigation deterministic even when the current file contains no marks.

**Non-Goals:**

- Migrating `marks.nvim`'s buffer-local lowercase marks (names can conflict
  across buffers).
- Synchronizing live writes from multiple simultaneous Neovim instances or
  tracking edits while the marked file is not loaded.
- Changing Neovim's backtick exact-column jumps or mark operations in
  Visual/Operator-pending mode.

## Decisions

### One store keyed by lowercase name

Create `moonshine.nvim/jumper.nvim/lua/moonshine/jumper/` with a table of 26
possible entries `{ path, row, col }` (absolute normalized path; one-based row,
zero-based column). Serialize to a versioned JSON file beneath
`vim.fn.stdpath("data")`, using validated reads and atomic temp-file + rename
writes. Write on set/delete and flush tracked positions on buffer
lifecycle/exit; avoid data loss on malformed JSON by warning and declining to
overwrite the unreadable store. On reopening a file, clamp saved coordinates to
valid buffer contents. Prefer a dedicated store to native uppercase marks (which
would consume the user's `A`–`Z` namespace) or per-buffer lowercase marks (which
cannot enforce global uniqueness).

### Track loaded positions with extmarks

For every loaded normal file matching a stored path, create/update one extmark
per name in an internal namespace. Extmarks follow text edits; reconcile them to
persisted coordinates on `BufWritePost`, `BufUnload`/`BufDelete`, and
`VimLeavePre`, and when jumping or displaying a mark. On file open/enter,
hydrate from persisted coordinates; avoid creating a file when a destination is
missing and leave it in the store for explicit deletion. Coalesce persisted
writes if edit tracking would otherwise generate excessive I/O. An
unloaded/external edit cannot be tracked; clamp and persist corrected
coordinates on next open instead.

### Map only lowercase sequences, not the `m` or `'` prefix

Register 26 Normal-mode `m{letter}` and 26 `'{letter}` mappings via
`local map = require "mappings.map"` in `lua/mappings/jumper.lua`, leaving `mA`,
`''`, and other native prefix sequences intact. `dm` deletes marks on the cursor
line, `<leader>dm` deletes current-file marks, and a user command such as
`:JumperDelete p` deletes one mark (with input validation). Unnamed/technical
buffers refuse setting a persistent mark with feedback. Do not install mappings
inside the plugin using `vim.keymap.set`: the repository's `langmapper` wrapper
is mandatory. Remove `marks.nvim` and its setup instead of layering competing
mappings.

### Traverse names, not positions

Store the most recently jumped-to/traversed letter as the traversal anchor.
`]m`/`[m` advance to the next/previous assigned letter with wrap, skip gaps, and
apply `vim.v.count1` steps; when there is no anchor, use the mark at the current
cursor if present, otherwise start at the first/last assigned name. If an anchor
is deleted, fall back to the same cursor-based rule. A successful traversal
installs forward/backward callbacks in `moonshine.utils.navigation_repeat`;
`]]`/`[[` delegate to that helper, so they repeat the most recent navigation of
any kind, not only marks. `;`, `<A-;>`, `n`, and `N` keep their existing global
behavior. This is preferred to sorting marks by file/line because the requested
order is alphabetical across files.

### Render a dedicated mark segment beside existing sign segments

Expose a read-only `jumper` lookup of letters on a visible buffer line, and add
a small text segment in `lua/configs/statuscolumn.lua` adjacent to the existing
sign segments; display all letters on a line in alphabetical order. Rebuild a
per-buffer line index on mark changes/text edits, not on each status-column
evaluation; request redraws when positions change. A separate segment avoids the
wildcard sign segment swallowing mark signs or displacing diff/diagnostic signs.
Respect the current status-column ignore/hidden-gutter behavior for technical
buffers.

## Risks / Trade-offs

- [Native lowercase marks saved in shada coexist with new mappings] → document
  that `jumper` owns mapped lowercase mark operations only; clear/migrate native
  marks only if explicitly requested.
- [Two Neovim instances edit the same JSON store] → use atomic writes to avoid
  partial files; concurrent last-writer-wins is out of scope.
- [Extmark gravity or buffer unload changes positions unexpectedly] → verify
  insertion/deletion and reopen behavior with headless Neovim checks and clamp
  invalid coordinates.
- [Fixed sign space versus many letters on one line] → render all letters in the
  dedicated segment and verify mixed-mark/diagnostic/diff layout; adjust segment
  width if necessary rather than hiding marks.
- [Mapping `]]`/`[[` overrides native section movement] → explicitly document
  the keybinding change and leave all unrelated native mark commands alone.

## Migration Plan

1. Remove the `marks.nvim` plugin spec/setup; add local `jumper` config and
   mappings, retaining `dm` and `<leader>dm` with the new store.
2. Add the status-column segment and verify signs, folds, and hidden technical
   gutters still work.
3. Ship an empty store on first launch; users can set new global lowercase
   marks. Rollback by restoring the old plugin/config/mappings; the independent
   JSON store can remain unused without altering native marks.
