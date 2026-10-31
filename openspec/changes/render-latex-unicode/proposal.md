# Proposal

## Why

Markdown math should display readable Unicode symbols in Neovim: `\alpha` as α and `\cdot` as ⋅. The current render-markdown configuration enables LaTeX, but its default external converters are absent and `conceallevel=0` prevents source replacement.

## What Changes

- Render supported LaTeX commands as Unicode inside inline and display Markdown math, including Greek letters, common operators, and distinct dot variants.
- Apply substitutions only to the display; preserve the original LaTeX in the buffer and on disk.
- Preserve visible Markdown markers, existing render toggles, and ordinary prose and code.
- Hide `\left` / `\right` sizing commands while preserving visible delimiters; support arrows, sets, logic, calculus symbols and named functions. Render complete braced fractions with a Unicode division sign and square roots with √; leave scripts and accents as written.
- Render spacing commands such as `\qquad` and use a consistent normal-text foreground for source and replacements.
- Keep unsupported commands readable rather than dropping them or reporting converter errors.
- Use the installed render-markdown custom-handler integration for symbol substitution without requiring a full formula converter.

## Capabilities

### New Capabilities

- `markdown-math-rendering`: Unicode presentation of LaTeX symbols in Markdown math with editable source and safe fallback.

### Modified Capabilities

None. The main OpenSpec specs directory currently has no capabilities.

## Impact

Planned changes affect `lua/configs/render-markdown.lua`, a small local math-symbol handler, focused verification fixtures, and README usage guidance. Conceal settings and Markdown Tree-sitter conceal directives need coordinated handling so source Markdown markers remain visible. Implementation uses only local configuration and the installed parsers/plugin; no external converter or plugin source changes are required.
