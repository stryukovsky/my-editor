# Preview math/table verification

Implemented locally in the config and its installed render-markdown fork on 2026-10-31.

## Cause and result

At a 48-column preview width, table formatting split raw `\frac` / `\sqrt` commands across table rows. The subsequent source-based math overlay treated generated table borders as part of the expression and erased/shifted them. The preview now materializes compact Unicode before table widths and prose wrapping are calculated. Its finished buffer has actual mathematical text and no math overlays. Direct source-buffer rendering retains its existing source-width-preserving behavior.

## Checks

- 636 focused math checks with the supplied AMM note passed, including copied text conversion, nested expressions, code exclusion, safe Unicode bars, line count, unchanged source and existing source-mode width behavior.
- 57 Plenary tests passed: preview transform (1), preview (2), heading navigation (10), Mermaid lifecycle (4), table wrapping (23), heading sync (5), table text (5), and prose wrapping (7).
- `tests/markdown_math_preview_ui.py` passed: actual Unicode buffer text, 48-column table geometry and visible borders, nested math, Unicode content, math bars, code spans/fences, heading rows, source bytes/flags/undo, absence of late math overlays, and refresh after source edits.
- Existing math/source UI, heading-navigation UI and real Mermaid/inspection UI checks passed. Existing preview and source behavior was preserved.
- StyLua checks, strict OpenSpec validation and the incremental patch's forward/reverse checks passed.

## Recovery patch

`preview-math.patch` contains only this task's changes to the installed fork: the optional preprocessing hook, its documentation and a focused regression test. Apply it on top of the existing local preview/heading/Mermaid work. It is **not** a replacement patch against a clean upstream checkout. `preview-math-base.json` records the expected original preview-file digest and base commit. The patch was applied to a temporary copy and reproduced the edited files exactly; it is already installed locally and should not be applied again here.

No commit, push, plugin-pin update, source note edit or Neovim core edit was performed.

To rerun the plugin transform test, from the installed plugin directory:

```sh
nvim --headless --noplugin -u ~/.config/nvim/openspec/changes/render-latex-unicode/preview-test-init.lua -c "PlenaryBustedDirectory tests/preview_transform_spec.lua { minimal_init = '/home/dmitry/.config/nvim/openspec/changes/render-latex-unicode/preview-test-init.lua', sequential = true }"
```
