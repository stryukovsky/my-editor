# Tasks

## 1. Plugin converter

- [x] 1.1 Adapt the existing config's Mermaid ASCII subprocess/output handling into a plugin-owned asynchronous module with configurable executable, timeout, bounded cache, and pending-request deduplication; verify focused tests for stdin, ANSI removal, whitespace, repeated inputs, failure, missing executable, empty output, and timeout.
- [x] 1.2 Document the converter setting and supported-subset fallback in plugin docs; verify examples against the installed `bin/mermaid-ascii` command without personal config module dependencies.

## 2. Preview document integration

- [x] 2.1 Extract complete Mermaid fenced source spans before prose/table formatting and add literal source-span replacements to the document builder; verify tests for multiple diagrams, backticks/tildes, nested literal examples, unclosed fences, wide output, blank lines, and adjacent headings/tables.
- [x] 2.2 Connect conversion completion to preview refresh with generation/source-revision guards and close/delete cleanup; verify delayed-result tests for edited source, closed/replaced previews, duplicate requests, and mixed successful/failed blocks.
- [x] 2.3 Preserve source/preview navigation around diagram spans using the navigation model present when applying; verify content after a diagram maps correctly and source bytes, modified state, and undo history remain unchanged through open/refresh/close.
- [x] 2.4 Document preview diagram rendering and fallback behavior alongside the feature, then run focused preview/sync tests and the fork's required formatting/lint checks; verify existing table/prose tests pass.

## 3. Config shortcut integration

- [x] 3.1 Configure the plugin to use the existing bundled converter with PATH fallback and route Markdown `<A-i>` through the full preview toggle using `mappings.map`; verify real key input opens from prose, tables, and Mermaid source and returns from preview while preserving CSV/TSV/diagnostic behavior.
- [x] 3.2 Preserve table-row inspection on `<leader>mdi` and update mapping help/README with both shortcuts; verify no conflicting mapping and that standalone Mermaid visualization still works.

## 4. End-to-end acceptance

- [x] 4.1 Preview a mixed Markdown fixture with the real converter via `<A-i>`, edit a diagram, and close/reopen; verify diagram geometry, refresh, source preservation, and navigation after diagrams, then repeat with an unavailable converter to confirm literal fallback.
- [x] 4.2 Review both plugin-fork and config diffs, run `git diff --check` in each, and run `openspec validate render-mermaid-ascii-preview --strict`; verify the changes remain separately reviewable, unrelated work is preserved, and the lockfile is not manually edited.
