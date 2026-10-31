# Verification

Implemented 2026-10-31 in `/home/dmitry/.config/nvim` and its installed `stryukovsky/render-markdown.nvim` fork.

- 32 focused Plenary tests passed across Mermaid conversion, fenced-code extraction, preview lifecycle, existing preview navigation, source synchronization, prose wrapping, and table text formatting.
- `uv run --with pynvim python tests/markdown_mermaid_ui.py` passed using an attached 120x45 Neovim UI, the real bundled converter, and actual mapped input. It opens from prose/table/Mermaid positions, returns to source, checks diagram geometry and table/math rendering, edits and refreshes a diagram, checks missing-converter fallback, preserves source bytes/modified/undo state, tests inspection dispatch, and renders a standalone Mermaid file.
- Existing `tests/markdown_math.lua`: 96 checks passed.
- Whole-plugin `stylua --check .` passed. Config preview files also formatted with the config's StyLua settings.
- Selene on every changed/new plugin Lua file: 0 errors, 0 warnings, 0 parse errors.
- Whole-plugin Selene still reports 56 errors and 12 warnings. Its output is byte-for-byte identical to a clean archive of the original HEAD; these pre-existing issues are in other files and were not modified.
- `git diff --check` passed for plugin and config. Unrelated CSV, mapping-help, which-key, and heading-navigation work was preserved. No lockfile changes or Neovim core edits were made.

## Retained plugin patch

The installed plugin is ignored by the config repository. `plugin.patch` includes every implementation and test change, including new files, against plugin commit `6177a78b07c18ec7af8bd8116c8d5fc7483cb451`. It passed forward application checks against a clean archive of that commit and reverse application checks against the installed plugin.

The changes are already applied locally and remain uncommitted in the plugin checkout. The patch is a retained review/recovery artifact; do not apply it again to the current checkout. If a plugin update replaces the local edits, rebase/apply it in the fork before updating the pin through the normal plugin workflow. Nothing was pushed or published.

## Usage

Restart Neovim to load the edited Lua modules. In Markdown, `<A-i>` opens the complete preview with embedded Mermaid ASCII diagrams; `<A-i>` in the preview returns to source. `<leader>mdi` retains Markdown table-row inspection. Existing buffer-local CSV mappings remain intact.
