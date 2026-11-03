# Verification

Implemented on 2026-10-31 in the installed `stryukovsky/render-markdown.nvim` fork at `/home/dmitry/.config/nvim/data/lazy/render-markdown.nvim`.

## Results

- 77 focused Plenary tests passed across source/preview heading navigation, preview lifecycle, heading rendering, document symbols, prose wrapping, table wrapping/text formatting, fences, and asynchronous Mermaid rendering. The new navigation integration suite has 10 cases; the heading unit suite has 5.
- `uv run --with pynvim python tests/markdown_heading_navigation_ui.py` passed from the config root. It attaches a real 120x45 Neovim UI and exercises actual `<leader>mdr` input, bidirectional section follow, same-section movement, duplicate/nested headings, tables, code fences, Setext headings, origin cursor preservation, source bytes/undo preservation, edits and reopen.
- Selene on all affected plugin Lua files: 0 errors, 0 warnings, 0 parse errors. StyLua checks and `git diff --check` passed.
- The installed plugin's standard minimal test init expects mini.icons, which is not installed here. The retained `test_init.lua` uses existing parsers and Plenary without downloading dependencies. Run the selected files through `PlenaryBustedDirectory` with this file as `minimal_init`; test paths can be individual files. The 77-test run selected `tests/preview_spec.lua`, `tests/preview_navigation_spec.lua`, `tests/preview_mermaid_spec.lua`, `tests/heading_spec.lua`, `tests/table_wrap_spec.lua`, and unit `sync`, `wrap`, `table_text`, `fences`, and `document_symbol` specs.

## Retained implementation

`plugin.patch` includes all changed and added fork files against commit `fc2a7eccbdded47c146c89f66d6e4d11400111ff`. Forward application against a clean archive of that revision and reverse application against the current checkout both passed. The implementation is already applied locally; do not apply the patch again to this checkout.

The fork lives under ignored config `data/`, so the patch retains a review/recovery copy alongside this change. No commit, push, publication, plugin pin update, or Neovim core edit was performed. Integrate the patch into the fork through its normal review/update workflow before replacing this installed checkout. Unrelated Mermaid and config work is preserved.

## Usage

Restart Neovim to reload the changed modules. `<leader>mdr` and the existing Markdown inspection toggle use the current section heading in both directions. Moving inside a section leaves the counterpart cursor alone. Before the first heading or without headings, document start is the anchor. Long headings retain their syntax and use the preview's existing horizontal scrolling behavior.
