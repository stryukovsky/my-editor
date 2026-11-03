# Tasks

## 1. Verify the installed rendering APIs

- [x] 1.1 Capture representative inline/block math parse trees and confirm symbol command ranges, escaped backslashes, code exclusion, and incomplete-edit behavior with the installed parsers.
- [x] 1.2 Verify render-markdown custom-handler marks, render-mode controls, toggle cleanup and window-option restoration. Confirmed plugin pattern controls are global; implemented and tested the buffer-local query alternative from design.md to preserve backticks without changing other buffers.

## 2. Implement Unicode symbol presentation

- [x] 2.1 Add a small local handler with an explicit Greek/operator/arrow/dot/delimiter/function table, complete-command matching, escaped-command handling and unchanged unknown/structural syntax, plus hidden `\left` / `\right` sizing tokens.
- [x] 2.2 Register the handler in `lua/configs/render-markdown.lua`, coordinate rendered conceallevel and scoped query controls, and preserve current filetypes, render modes and toggles. Do not modify plugin installations or lazy-lock.json.

## 3. Verify and document

- [x] 3.1 Run focused headless fixtures covering every specified dot code point, representative Greek/operators, inline and multiline math, both configured filetypes, Unicode byte ranges, unknown-command prefixes, escaped backslashes, prose/code exclusion, edits and toggle cleanup.
- [x] 3.2 Verify unchanged buffer bytes, modified flag, undo history and saved output, plus rendering with no converter executables. Confirm unaffected non-Markdown buffers and restoration of window/query state.
- [x] 3.3 Inspect an attached Neovim UI for symbol spacing, wraps, narrow-window behavior and preserved Markdown markers; verify toggles and editing with the actual Markdown setup and installed plugin/parsers. Terminal font coverage remains environment-dependent.
- [x] 3.4 Document math delimiters, supported symbols, display-only behavior and the symbol-only limitation in README. Format touched Lua, run `git diff --check`, and record validation results.

Validation results are recorded in design.md.


## 4. AMM note readability follow-up

- [x] 4.1 Inspect the supplied AMM note read-only and add terminal spacing, min/max, complete braced fractions using ÷, and square roots, including nested arguments. Keep scripts, accents, unsupported/indexed forms and source unchanged.
- [x] 4.2 Replace gray conceal glyphs with uniformly highlighted inline text; apply the Normal foreground to the remaining formula source via the existing theme override flow.
- [x] 4.3 Run nested/incomplete/source-preservation fixtures and real-note parser/UI checks. Verify configured initial state, explicit enable, toggles, scrolling, consistent source/replacement colors and theme changes; update README and this change.


## 5. Math delimiter spaces

- [x] 5.1 Render dollar delimiter nodes as equal-width spaces; preserve code, escaped dollars, source text, and toggle restoration.
- [x] 5.2 Verify inline and display math with focused parser and UI checks, and update documentation and spec.

- [x] 5.3 Replace only the opening display-math `$$` with the Nerd Font LaTeX icon and trailing space; verify single-line and multiline display math, unchanged inline math, code, source and toggle restoration.


## 6. Source-width formula centering

- [x] 6.1 Keep each complete formula body compact and center it with only outer compensation padding. Preserve delimiter/icon spans and each multiline source row, with literal body fallback if a row would grow.
- [x] 6.2 Verify exact padding, Unicode, buffer-local variable tab stops, ambiguous-width glyphs, multiple inline regions, source/undo/toggle behavior, suffix columns and narrow-window wrap positions. Check every row of the supplied AMM note without modifying it.
- [x] 6.3 Update README, behavior specs and design with width-preserving rendering semantics and verification results.

- [x] 6.4 Move all individual symbol/expression compensation to the complete formula body edges; verify compact multi-symbol and nested expressions plus unchanged source width, suffix columns and wrapping.


## 7. Real preview math before table layout

- [x] 7.1 Reproduce raw-LaTeX wrapping and late math overlays overwriting table borders; isolate the preprocessing/layout order as the cause.
- [x] 7.2 Reuse syntax-aware math transformations to materialize copied Unicode input before preview prose/table layout. Preserve source rows, code and source state; skip late preview math overlays and keep math bars safe as table content.
- [x] 7.3 Verify actual buffer and screen table geometry, nested formulas, headings, source edits, source/undo preservation, existing source-mode rendering, Mermaid and navigation behavior. Retain the small installed-fork hook patch and documentation.
