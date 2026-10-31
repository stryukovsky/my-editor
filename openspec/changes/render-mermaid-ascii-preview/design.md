# Design

## Context

See proposal.md for motivation. Inspected active config at `/home/dmitry/.config/nvim` and the configured render-markdown fork at `data/lazy/render-markdown.nvim`; the chat workspace is an unrelated Neovim core checkout.

`lua/configs/mermaid.lua` resolves a bundled converter before PATH, invokes `mermaid-ascii -f -` with stdin and `NO_COLOR=1`, strips ANSI color, and caches ten outputs. It depends on Plenary and opens a separate scratch buffer. `lua/mappings/inspection.lua` dispatches `<A-i>` to this diagram popup, a Markdown row inspector, CSV/TSV inspection, or diagnostics.

The plugin's `core/preview.lua` creates a listed read-only preview and refreshes it using `sync.build`. That builder currently handles prose, gaps, and tables, with source/preview positions for each block. Conversion therefore belongs before prose/table formatting in the preview document pipeline. Extmarks alone would leave code in the preview's actual text and symbol navigation.

## Goals / Non-Goals

**Goals:** Put reusable conversion in the plugin, preserve document block identity, and reuse the installed converter. Keep asynchronous results tied to the current preview and source revision.

**Non-Goals:** Browser preview, PNG rendering, implementing Mermaid syntax, rendering diagrams in editable source buffers, and the separate heading-navigation redesign.

## Decisions

### Plugin-owned converter adapted from existing config

Add a small plugin module using `vim.system` directly; copy the established stdin protocol, ANSI cleanup, and bounded cache approach without importing personal `configs.*`, scratch-window helpers, or Plenary. Use a configurable executable, with PATH as the portable default. The personal setup supplies the bundled executable when present. Cache by complete source text and executable identity, avoiding the existing small rolling hash's collision risk. Cache failures for unchanged input to avoid repeated notifications; provide invalidation on reopen or converter setting changes.

Use a finite process timeout and keep converter calls asynchronous. A synchronous subprocess in `refresh` would freeze the editor; a new browser/image dependency would discard the existing terminal workflow.

### Source blocks and literal output

Use the Markdown parser's fenced-code nodes and language information to identify complete Mermaid fences, including backtick and tilde forms. Derive the exact source span and code content before wrapping. Keep a fence-aware fallback or preserve literal fenced regions when a parser is unavailable; never scan blindly for Mermaid-looking lines inside other code blocks.

Extend the document builder with optional source-span replacements. Successful diagrams become literal blocks whose output bypasses prose wrapping and table parsing. Pending and failed blocks retain their original lines verbatim. Add this as an optional argument so existing builder callers remain compatible. Preserve trailing/interior spaces and strip only terminal line endings and ANSI colors from converter output. Carry source and preview spans for replacements so following content stays aligned.

For the current navigation implementation, literal diagram blocks map inside their own source/preview spans with a bounded row mapping and column zero. If heading-based synchronization lands first, use its heading identities instead; diagrams cannot introduce headings. Do not add a second navigation subsystem.

### Refresh and lifecycle

Initially build the preview with literal pending fences. Start one conversion per unique uncached diagram, then rebuild the document as results become available. Capture the source changedtick, preview identity, and refresh generation. Drop callbacks for deleted buffers, closed/replaced previews, changed settings, or superseded revisions. Rebuild using current source and normal highlighting/cursor restoration; do not open any window from converter callbacks.

Deduplicate pending identical requests, retain a bounded cache, and report a concise failure once per unchanged failed input. Close/delete cancels owned work when possible and always invalidates callbacks.

### Shortcut integration

In `inspection.lua`, route Markdown `<A-i>` through the existing render-markdown preview entry point and enable the resulting preview buffer as the existing `<leader>mdr` mapping does. Preserve non-Markdown dispatch. Move Markdown row inspection to `<leader>mdi`, using `mappings.map`; update mapping help and README. Keep standalone `.mmd`/`.mermaid` visualization mappings intact.

## Risks / Trade-offs

- Converter supports only its own Mermaid subset → keep literal source with a concise diagnostic on rejection; do not promise all Mermaid diagram types.
- Very wide diagrams exceed preview width → preserve geometry and allow existing window navigation rather than reflowing text.
- Async refresh moves the cursor after output height changes → reuse document source anchors and verify navigation after diagrams.
- Concurrent heading-sync work touches the same files → keep diagram replacements isolated and adapt to the navigation implementation present when applying.
- Plugin installation is ignored by config Git → retain and review fork changes separately; do not rely on a config commit to save plugin implementation.

## Migration Plan

Implement and test in the plugin fork, then configure its converter and keymaps in the config repository. Verify the bundled executable and real `<A-i>` input end to end. Do not push or publish without user instructions; do not hand-edit the lockfile. Rollback reverts the fork conversion changes and config integration, restoring the previous inspection mapping; Markdown files need no migration.
