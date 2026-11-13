# Tasks

## 1. Persistent mark store

- [x] 1.1 Add `moonshine.nvim/jumper.nvim/lua/moonshine/jumper/` with validated
      lowercase-name CRUD and a versioned JSON store under patched
      `stdpath("data")`; verify with a headless Neovim script that assignments
      overwrite names, survive reload, and malformed data is not overwritten.
- [x] 1.2 Track loaded mark positions with extmarks and buffer/exit lifecycle
      hooks, clamping reopened positions and refusing unnamed/technical buffers;
      verify with headless insert-above, buffer-close/reopen, restart, and
      externally shortened-file cases.
- [x] 1.3 Implement cross-file jump and name/line/file deletion APIs including
      safe missing-target handling; verify with headless A/B/C buffers that
      deleted or inaccessible marks do not change the current cursor/buffer or
      create a file.

## 2. Navigation and keybindings

- [x] 2.1 Implement alphabetical next/previous navigation, wrap, counts,
      cursor/anchor selection, and registration with
      `moonshine.utils.navigation_repeat`; verify headless A/B/C traversal (`o`
      to `p`, `v` to `m`), empty-set notification, and reverse repeat.
- [x] 2.2 Replace `marks.nvim` in `lua/plugins/core.lua` and
      `lua/configs/init.lua`, remove obsolete `lua/configs/marks.lua`, and
      register the local plugin setup; verify startup loads exactly one mark
      manager and does not modify `lazy-lock.json` by hand.
- [x] 2.3 Add `lua/mappings/jumper.lua` through `lua/mappings/init.lua` using
      `mappings.map` for `m{a-z}`, `'{a-z}`, `]m`, `[m`, `]]`, `[[`, `dm`,
      `<leader>dm`, plus named deletion command; verify mappings preserve native
      `mA`/`''` and repeat through `;`, `n`, `N`, and `<A-;>`.

## 3. Status-column presentation

- [x] 3.1 Add an efficient per-buffer line-to-letters view and render it in
      `lua/configs/statuscolumn.lua` alongside existing sign segments; verify
      visible letters after mark set/move/delete, edits and buffer reopen,
      including multiple marks on one line.
- [x] 3.2 Exercise status-column integration with diff/diagnostic signs, folds,
      and hidden technical gutters in a headless or interactive Neovim check;
      verify no existing signs disappear and technical buffers remain
      gutter-free.

## 4. Integration verification

- [x] 4.1 Run the headless checks and
      `openspec validate add-jumper-marks --strict`, then manually verify A(mno)
      → B(pqr) → C(tuv), persistence across a real restart, alphabetical
      `]m`/`[m` and all requested repeat keys; record any remaining
      environment-specific limitations in the implementation summary.
