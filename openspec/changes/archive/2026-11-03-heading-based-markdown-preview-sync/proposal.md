# Proposal

## Why

The rendered Markdown preview changes line layout through wrapping and table formatting, making the existing line and paragraph cursor synchronization a poor navigation anchor. Source and preview should share the most recent heading at or before the active cursor so navigation stays aligned with the document structure.

## What Changes

- Replace source/preview line, paragraph, and table-ratio navigation mapping with heading-based synchronization in both directions.
- Resolve the current section as the last heading at or before the active cursor in document order, including nested headings, and move the counterpart to that heading only when the section changes.
- Use the same heading anchor when opening, reopening, refreshing, and closing a preview, including when the counterpart buffer is hidden.
- Pair headings by their source occurrence through rendering rather than matching title text; support repeated titles and ATX/Setext headings without recognizing code-block text as headings.
- Treat the document beginning as the anchor before the first heading and for documents without headings.
- Remove obsolete navigation mapping state and tests while retaining prose wrapping, table formatting, rendering, and preview symbol navigation.

## Capabilities

### New Capabilities

- `markdown-preview-navigation`: Structural navigation synchronization between a Markdown source buffer and its rendered preview, including section identity and preview lifecycle behavior.

### Modified Capabilities

None. The current main specification inventory has no Markdown preview navigation capability.

## Impact

- Implementation belongs to the configured `stryukovsky/render-markdown.nvim` fork, currently checked out at `/home/dmitry/.config/nvim/data/lazy/render-markdown.nvim`, particularly `lua/render-markdown/core/preview.lua` and `lua/render-markdown/sync/`.
- Existing `integ/lsp.lua` heading extraction provides a reusable parser-based starting point; navigation must not require an attached LSP client.
- Update `tests/preview_spec.lua`, `tests/unit/sync_spec.lua`, and fork preview documentation. Preserve unrelated wrapping and table tests.
- The Neovim config keymaps and setup remain the integration entry points. The plugin checkout is ignored by the config repository, so implementation must be retained in the fork rather than relying on untracked installed-file edits; lock updates use the normal plugin workflow.
- Browser `MarkdownPreview`, PDF export, math rendering, and Neovim core source are outside this change. No new dependency or keymap is proposed.
