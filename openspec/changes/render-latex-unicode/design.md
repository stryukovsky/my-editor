# Design

## Context

See proposal.md for motivation. The actual configuration repository is `~/.config/nvim`; the chat workspace is the separate Neovim source tree at `~/Work/neovim`.

`lua/configs/render-markdown.lua` enables LaTeX for `markdown` and `todotxt-preview`, disables anti-conceal, and sets rendered conceallevel to zero specifically to keep Markdown source markers visible. The installed plugin's default LaTeX handler invokes `utftex` or `latex2text`, neither of which is currently executable. Its center positioning uses an inline virtual-text mark plus conceal; simply installing a converter does not solve the conceal conflict.

The installed plugin supports a custom handler per Tree-sitter language, with `extends=false` replacing the built-in handler. The Markdown and markdown_inline highlight queries also contain conceal directives, so raising conceallevel alone would change unrelated presentation.

## Goals / Non-Goals

**Goals:** readable symbols, unchanged buffer bytes, bounded parsing of recognized math, preserved Markdown markers and plugin lifecycle.

**Non-Goals:** stacked fraction typesetting, matrices or scalable brackets; image previews; arbitrary TeX execution; converting commands in prose or code; changing completion or PDF export.

## Decisions

### Substitute symbols through a custom LaTeX handler

Register a local LaTeX handler through the existing render-markdown handler API, replacing rather than extending its converter handler. Walk recognized LaTeX command nodes inside Markdown math injections and emit plugin-managed marks for supported command spans. Match complete command names, respect escaped backslashes, and preserve unknown commands and structural syntax verbatim. This reuses the plugin's parsing, refresh, toggle and cleanup lifecycle without introducing a second buffer renderer.

Use an explicit reviewed symbol table: standard Greek letters and variants, common binary/relation operators, arrows, and the dot mappings defined by the spec. Argument-taking commands are limited to complete braced fractions and square roots; accent commands remain literal. Do not partially convert longer command names sharing a supported prefix.

Alternative: install `latex2text` and keep the built-in handler. That is useful for broader formula conversion but adds an external runtime and formula-wide transformation where this request needs symbol substitutions. Alternative: global regex replacement risks touching prose/code and changing source text.

### Coordinate symbol conceal and existing Markdown visibility

Use empty conceal plus inline virtual text for replacements and rendered conceallevel 2, restoring the existing unrendered value when rendering is disabled. Keep anti-conceal and render modes consistent with the current configuration.

The installed plugin's pattern controls disable shared queries globally and initialize only once, so they cannot provide buffer-scoped restoration. Use the scoped fallback: compile highlight queries without `conceal` / `conceal_lines` directives and swap only the rendered buffer's highlighter query references in `on.render`. Restore the original references in `on.clear`. Cache compiled queries; preserve captures and predicates, and never mutate the shared query cache or runtime files. Apply this to Markdown, markdown_inline and injected LaTeX highlighting so only our explicit symbol marks conceal source.

This uses Neovim's internal highlighter query wrapper `_query` field through one isolated adapter. The headless and attached-UI fixtures verify buffer isolation and restoration with the installed Neovim. Re-run these fixtures after Neovim highlighter changes.

Alternative: raising conceallevel without query coordination would hide backticks and other currently visible source markers. Overlaying a short symbol at conceallevel zero would leave unwanted command characters and incorrect spacing.

### Preserve source and unsupported constructs

Display inline dollar delimiters as spaces and the opening display delimiter as a LaTeX icon, while keeping unsupported structural LaTeX source visible. Hide `\left` and `\right` sizing tokens while preserving their delimiters, converting escaped braces, angle brackets and vertical bars. A dot used as their invisible delimiter is also hidden. Do not transform superscripts, subscripts or accents. Replace only recognized symbol-command spans, including within a multiline math region. Toggle-off shows the full original commands. Unsupported commands remain as written, with no external process, destructive fallback or error placeholders.

### Linear fractions, square roots and spacing

Use Tree-sitter generic-command argument fields to recognize complete `\frac`, `\dfrac`, `\tfrac` and `\sqrt` expressions. Replace only their command and outer brace spans: `\frac{xy}{x+a}` displays as `(xy) ÷ (x+a)`, and `\sqrt{xy}` displays as `√(xy)`. Recurse into arguments for nested roots, fractions and symbols without overlapping marks. Keep internal subscript/superscript/accents source intact. Unbraced, indexed and incomplete structures remain literal. This avoids copying expressions into a separate flattened representation and preserves multiline source layout.

Map `\quad` and `\qquad` to two and four terminal spaces. Small spacing commands and escaped spaces use one cell; `\!` disappears rather than trying to overlap terminal glyphs. Add `\min` and `\max` to named functions found in the example note.

### Consistent math foreground

Conceal replacement characters use Neovim's global `Conceal` highlight, which caused gray symbols next to blue source. Use inline virtual text with `RenderMarkdownMath` for every nonempty replacement. Add one higher-priority math-region foreground mark for the remaining source. Set `RenderMarkdownMath` to the current `Normal` foreground in the existing highlight override function, so ColorScheme/UIEnter refresh both uniformly. Do not modify the global Conceal highlight or unrelated Markdown/LaTeX buffers.

## Risks / Trade-offs

- Query pattern controls may vary with the installed plugin version → prove buffer scoping, marker visibility and cleanup before enabling conceal.
- Unicode widths and glyph coverage depend on the terminal font → verify representative Greek, operator and dot symbols in a normal and narrow window.
- Incomplete math can produce partial parse trees → skip unreliable nodes and verify edits recover cleanly.
- Linear fractions and roots preserve precedence through parentheses but do not provide stacked typesetting → document the display contract and leave unsupported structures literal.

## Rollout and Rollback

Implement and validate the handler in the config repository, then enable it through render-markdown setup. Rollback restores the existing LaTeX handler and window options and removes the local handler and query-control configuration. No document conversion or data migration is needed.


## Verification

- `nvim --headless -u NONE -i NONE -l tests/markdown_math.lua`: 96 checks passed by default; 107 with the optional AMM note with installed parsers, including exact dots, escaped delimiters, both filetypes, unknown prefixes, escaped commands, code/prose exclusion, edits, local query restoration and source/undo preservation.
- `uv run --with pynvim python tests/markdown_math_ui.py`: attached Neovim UI verified configured opening behavior and explicit enable, visible symbols and backticks, saved bytes, cursor-line rendering, toggles, edits, narrow-window wraps, custom preview filetype and unrelated buffer isolation.
- The UI fixture loads the actual Markdown rendering setup with installed plugin/parsers; it does not load unrelated personal plugins or verify terminal font glyph coverage.

- Expanded fixtures cover linear ÷ fractions, nested √ roots, spacing, incomplete/unsupported structures and consistent math/source foreground across two theme foregrounds.
- Read-only validation against `~/Work/my-vault/Economics/AMM Theory/Выпуклость пространства.md` covered all 15 fractions and 7 roots, plus representative actual viewport display after scrolling. The vault note was never modified.

- Preserve the concurrent user setting `enabled=false` and preview-enable mapping. The UI fixture verifies the configured default, then explicitly enables rendering when required.

- Inline dollar delimiter nodes render as one space. The first `$$` child of a displayed equation renders as ` ` (the same LaTeX Nerd Font glyph used by the installed nvim-web-devicons tex icon); the closing `$$` remains two spaces. Escaped dollar commands and dollars in code are unchanged; plugin toggles restore the original delimiters with source bytes preserved.
