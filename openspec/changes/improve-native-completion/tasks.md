# Tasks

## 1. Ranking contract and native compatibility

- [ ] 1.1 Add a focused headless fixture entrypoint for the installed Neovim 0.12.6 completion APIs. Cover keyword, member, filterText, server text-edit start, empty base, punctuation, and UTF-16/non-ASCII boundaries; verify derived bases match the spec before wiring the new comparator. Record the invocation and supported version in README.
- [ ] 1.2 Implement immutable ranking keys in a small Lua module using public fuzzy scoring and safe metadata defaults. Verify exact/prefix/fuzzy classes, current-line affinity before fine fuzzy scoring, deprecation, snippets, missing fields, and empty bases with the spec's examples; document the precedence alongside the module.
- [ ] 1.3 Implement single-client server ordering and whole-snapshot omission of server keys for multiple enabled clients. Add shuffled-list and triple-comparison fixtures for irreflexivity, transitivity, missing keys, identical labels, and distinguishable insertion actions; verify repeated shuffles yield the same distinguishable order.
- [ ] 1.4 Integrate the module through the existing `vim.lsp.completion.enable` comparator, retaining `fuzzy,nosort,noselect`. Verify edits, cursor/buffer changes, and LSP attach/detach invalidate ranking state. Compare fixture output with both the old kind-first policy and a temporary native-default control, and document intentional differences.

- [ ] 1.5 Add current-line identifier affinity and fixtures for `User` versus `createUser`/`createCat`, camel/snake/acronym boundaries, substring rejection, duplicate mentions, query-span exclusion, keywords, comments/strings, missing syntax, and line-only edits. Verify exact matches still win and context is extracted once per snapshot; document this separately from typed-prefix relevance.

## 2. Conservative syntax context

- [ ] 2.1 Add bounded Lua and TypeScript/TSX context adapters using available syntax trees, with neutral fallback. Verify type annotations, colon-method access, dot-member access, imports, call arguments, comments, strings, incomplete expressions, missing/error nodes, missing parsers, unsupported languages, and ambiguous injections against real installed grammar fixtures. Document supported grammars and the syntax-versus-semantics limit.
- [ ] 2.2 Apply syntax fit only at its specified tie-break position. Verify a syntax hint cannot outrank a stronger text match or applicable single-server preference, generic dot access treats fields and methods equally, and no candidate is removed. Instrument fixtures to confirm context is captured outside repeated item comparisons and parser work is not repeated per candidate pair.

## 3. Readable menu and preserved acceptance

- [ ] 3.1 Set 10-row/70-column popup limits and add Unicode-safe, single-line display-only conversion for 45-cell names and 24-cell descriptions. Verify long signatures, multiline details, tabs/control characters, combining/wide characters, and narrow screens; confirm native kind labels, borders, and wheat colors remain readable. Document menu bounds in README.
- [ ] 3.2 Add a minimal fake-LSP acceptance fixture covering shortened labels, snippet expansion, resolved documentation, commands, auto-import edits, and two same-label items with different actions. Verify full insertion and native edits still occur, and Enter/Ctrl-Enter behavior remains unchanged. Record any terminal-specific acceptance check separately from LSP fixtures.

## 4. Explicit word fallback

- [ ] 4.1 Add the `<C-x><C-n>` word-source mapping through `mappings.map`, respecting enabled ordinary buffers and cancelling an open popup before switching. Verify current/window/loaded-buffer words with LSP attached, no accidental acceptance, unchanged `<C-Space>`, and unchanged terminal/disabled-buffer behavior. Document the shortcut and the absence of automatic empty-result fallback.
- [ ] 4.2 Exercise the sequential shortcut through langmapper in English and Russian layouts, including when an LSP popup is open and after fallback cancellation. Verify it does not recurse or trigger a conflicting mapping; retain the same observable shortcut behavior if the expression implementation changes.

## 5. Integration and rollout

- [ ] 5.1 Run the focused headless suite and formatter on touched Lua files, and `git diff --check`. Profile 1,000 mixed candidates with key-cache counters; record elapsed ranking time and confirm no parser traversal, LSP request, or full-buffer scan occurs per comparison. Investigate results above the design's local 10 ms target before enabling the sorter.
- [ ] 5.2 Validate a live Lua session, TypeScript auto-import/snippet session, unsupported language, terminal command buffer, disabled input, floating input, and a narrow window. Confirm the spec's visible order, menu limits, wheat styling, fallback, and native acceptance. Summarize results and the exact rollback files in the change's verification notes.

## Workflow follow-up

- Archive after implementation and verification are complete.
- Consider automatic empty-response fallback only as a separate change with a public hook or an explicit design for response aggregation, cancellation, stale responses, and native acceptance side effects.
