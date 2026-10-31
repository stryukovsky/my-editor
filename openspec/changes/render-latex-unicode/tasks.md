# Tasks

## 1. Verify the installed rendering APIs

- [ ] 1.1 Capture representative inline/block math parse trees and confirm symbol command ranges, escaped backslashes, code exclusion, and incomplete-edit behavior with the installed parsers.
- [ ] 1.2 Verify render-markdown custom-handler marks, render-mode controls, toggle cleanup and window-option restoration. Confirm query conceal controls can preserve backticks and other markers without affecting unrelated buffers; implement the scoped alternative from design.md if necessary.

## 2. Implement Unicode symbol presentation

- [ ] 2.1 Add a small local handler with an explicit Greek/operator/arrow/dot table, complete-command matching, escaped-command handling and unchanged unknown/structural syntax.
- [ ] 2.2 Register the handler in `lua/configs/render-markdown.lua`, coordinate rendered conceallevel and scoped query controls, and preserve current filetypes, render modes and toggles. Do not modify plugin installations or lazy-lock.json.

## 3. Verify and document

- [ ] 3.1 Run focused headless fixtures covering every specified dot code point, representative Greek/operators, inline and multiline math, both configured filetypes, Unicode byte ranges, unknown-command prefixes, escaped backslashes, prose/code exclusion, edits and toggle cleanup.
- [ ] 3.2 Verify unchanged buffer bytes, modified flag, undo history and saved output, plus rendering with no converter executables. Confirm unaffected non-Markdown buffers and restoration of window/query state.
- [ ] 3.3 Inspect a real Neovim window for symbol spacing, wraps, narrow-window behavior and preserved Markdown markers; verify toggles and editing in the user's existing configuration.
- [ ] 3.4 Document math delimiters, supported symbols, display-only behavior and the symbol-only limitation in README. Format touched Lua, run `git diff --check`, and record validation results.
