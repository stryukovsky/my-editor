# Proposal

## Why

The Markdown preview currently displays Mermaid fences as source text even though the config already renders individual diagrams with `mermaid-ascii`. A single `<A-i>` should open the complete rendered document, including diagrams, without requiring a separate diagram window.

## What Changes

- Render complete Mermaid fenced code blocks as ASCII diagrams inside the render-markdown preview buffer.
- Adapt the existing `lua/configs/mermaid.lua` subprocess, output cleanup, and caching approach into the render-markdown plugin source without a dependency on personal config modules or Plenary.
- Keep source Markdown intact and preserve the literal code when the converter is unavailable or rendering fails.
- **BREAKING**: In Markdown buffers, `<A-i>` toggles the full Markdown preview, replacing its current Mermaid-only/table-row inspection action. Other filetypes retain their inspection actions. Keep table-row inspection available through a separate explicit mapping.
- Preserve diagram spacing, surrounding Markdown rendering, preview refresh/close behavior, and source/preview navigation across changed line counts.

## Capabilities

### New Capabilities

- `markdown-preview-diagrams`: Mermaid conversion, failure fallback, source preservation, and the Markdown preview entry point.

### Modified Capabilities

None. `openspec list --specs` reports no existing main specifications.

## Impact

- Primary implementation: the `stryukovsky/render-markdown.nvim` fork installed at `data/lazy/render-markdown.nvim`, especially `core/preview.lua`, the `sync/` document builder, a plugin-owned Mermaid converter, and focused plugin tests/docs.
- Integration: `lua/mappings/inspection.lua`, `lua/mappings/markdownpreview.lua`, mapping help, and plugin converter configuration as needed. Use the existing `mappings.map` wrapper.
- Dependency: the existing `bin/mermaid-ascii` executable or a configured/PATH executable; no browser, image renderer, or network conversion.
- Coordinate with the separate `heading-based-markdown-preview-sync` proposal without implementing its navigation redesign here. Do not edit Neovim core, other previews, unrelated config changes, or manually update `lazy-lock.json`.
- The plugin installation is ignored by the config repository. Retain implementation as reviewable changes in the plugin fork; installation-only edits are not durable across plugin updates.
