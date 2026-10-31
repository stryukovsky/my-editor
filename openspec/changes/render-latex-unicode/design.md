# Design

## Context

See proposal.md for motivation. The actual configuration repository is `~/.config/nvim`; the chat workspace is the separate Neovim source tree at `~/Work/neovim`.

`lua/configs/render-markdown.lua` enables LaTeX for `markdown` and `todotxt-preview`, disables anti-conceal, and sets rendered conceallevel to zero specifically to keep Markdown source markers visible. The installed plugin's default LaTeX handler invokes `utftex` or `latex2text`, neither of which is currently executable. Its center positioning uses an inline virtual-text mark plus conceal; simply installing a converter does not solve the conceal conflict.

The installed plugin supports a custom handler per Tree-sitter language, with `extends=false` replacing the built-in handler. The Markdown and markdown_inline highlight queries also contain conceal directives, so raising conceallevel alone would change unrelated presentation.

## Goals / Non-Goals

**Goals:** readable symbols, unchanged buffer bytes, bounded parsing of recognized math, preserved Markdown markers and plugin lifecycle.

**Non-Goals:** typesetting fractions, matrices or scalable brackets; image previews; arbitrary TeX execution; converting commands in prose or code; changing completion or PDF export.

## Decisions

### Substitute symbols through a custom LaTeX handler

Register a local LaTeX handler through the existing render-markdown handler API, replacing rather than extending its converter handler. Walk recognized LaTeX command nodes inside Markdown math injections and emit plugin-managed marks for supported command spans. Match complete command names, respect escaped backslashes, and preserve unknown commands and structural syntax verbatim. This reuses the plugin's parsing, refresh, toggle and cleanup lifecycle without introducing a second buffer renderer.

Use an explicit reviewed symbol table: standard Greek letters and variants, common binary/relation operators, arrows, and the dot mappings defined by the spec. Supported commands with arguments, such as accent commands, are outside this first implementation. Do not partially convert longer command names sharing a supported prefix.

Alternative: install `latex2text` and keep the built-in handler. That is useful for broader formula conversion but adds an external runtime and formula-wide transformation where this request needs symbol substitutions. Alternative: global regex replacement risks touching prose/code and changing source text.

### Coordinate symbol conceal and existing Markdown visibility

Use conceal replacement for individual command spans and rendered conceallevel 2, restoring the existing unrendered value when rendering is disabled. Keep anti-conceal and render modes consistent with the current configuration.

Suppress the existing Markdown and markdown_inline query conceal directives in rendered buffers through the plugin's pattern-control mechanism. Resolve directive identifiers from active query metadata rather than copying numeric IDs from a particular grammar version. Preserve highlight captures and keep this scoped to rendered Markdown buffers; do not edit installed plugins or global runtime query files. Verify the installed pattern-control implementation before wiring it; if it cannot provide the required scoping, use buffer-local highlight-query handling with equivalent lifecycle cleanup. This compatibility check is an explicit implementation task, not permission to hide Markdown markers.

Alternative: raising conceallevel without query coordination would hide backticks and other currently visible source markers. Overlaying a short symbol at conceallevel zero would leave unwanted command characters and incorrect spacing.

### Preserve source and unsupported constructs

Keep math delimiters and structural LaTeX source visible in this symbol-only renderer. Replace only recognized symbol-command spans, including within a multiline math region. Toggle-off shows the full original commands. Unsupported commands remain as written, with no external process, destructive fallback or error placeholders.

## Risks / Trade-offs

- Query pattern controls may vary with the installed plugin version → prove buffer scoping, marker visibility and cleanup before enabling conceal.
- Unicode widths and glyph coverage depend on the terminal font → verify representative Greek, operator and dot symbols in a normal and narrow window.
- Incomplete math can produce partial parse trees → skip unreliable nodes and verify edits recover cleanly.
- A symbol table intentionally leaves structural commands such as `\frac` visible → document this boundary rather than claiming full LaTeX typesetting.

## Rollout and Rollback

Implement and validate the handler in the config repository, then enable it through render-markdown setup. Rollback restores the existing LaTeX handler and window options and removes the local handler and query-control configuration. No document conversion or data migration is needed.
