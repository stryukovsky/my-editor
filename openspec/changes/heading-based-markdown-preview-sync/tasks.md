# Tasks

## 1. Build structural heading anchors in the render-markdown fork

- [ ] 1.1 Add parser-based source heading extraction and paired emitted preview positions in `lua/render-markdown/sync/`, reusing existing heading traversal where practical without requiring an LSP client; verify focused unit cases for ATX, Setext, nested and repeated headings, empty titles, preamble, no headings, and code-block exclusions.
- [ ] 1.2 Preserve heading syntax during preview generation and keep prose/table output intact; verify long and multiline Setext headings remain indexed, heading pairs stay correct after expanded prose/tables, and existing rendering assertions pass.
- [ ] 1.3 Replace paragraph, wrapped-line, column, and table-ratio navigation with heading lookup; remove obsolete mapping-only metadata/helpers after checking callers, and replace old unit mapping assertions with heading-anchor tests while preserving output coverage. Verify no preview navigation path still invokes positional mapping.

## 2. Apply the section anchor throughout preview navigation

- [ ] 2.1 Update `core/preview.lua` cursor handling to maintain pair-local section state and move peers only on section changes; verify `tests/preview_spec.lua` covers both directions, backward motion, symbol jumps, movement within paragraphs/tables, preserved focus/origin cursor, and delayed-event bounce prevention.
- [ ] 2.2 Replace open/reopen, refresh, close, hidden-buffer, and wipeout use of old cursor anchors with structural state; verify lifecycle tests land on heading starts, handle preambles and heading-free documents, and isolate simultaneous preview pairs.
- [ ] 2.3 Track heading occurrence identity through edits and rebuild positions on text refresh; verify insertion before duplicate titles, renames, heading deletion with preceding-anchor fallback, and growth of earlier prose/tables with source-active and preview-active cases.
- [ ] 2.4 Document heading-based synchronization and heading-start return behavior in the fork's preview documentation and the config README where appropriate; verify examples match the existing `<leader>mdr` entry point and neither introduces scroll-position or exact cursor round-trip promises.

## 3. Verify integration and delivery

- [ ] 3.1 Run the fork's focused preview/sync tests, nearest wrapping/table/heading/symbol regression coverage, and affected lint/format checks using its existing Plenary/just tooling; record passing commands and any environment limitations.
- [ ] 3.2 Exercise `<leader>mdr` in the Neovim config with a heading-rich fixture containing duplicate titles, nested sections, long prose, tables, and code examples; verify source-to-preview and preview-to-source navigation, toggling and edits, and confirm the implementation diff belongs to the fork rather than Neovim core or only the config's ignored files.
