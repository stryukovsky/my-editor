# Design

## Context

See proposal.md for motivation. Observed on installed Neovim 0.12.6:

- `lua/configs/completion.lua` passes `cmp = compare` to `vim.lsp.completion.enable`. Its comparator ranks kind first and `sortText`/label second.
- Both normal and floating buffers use `fuzzy,nosort,noselect`. Fuzzy filtering remains active; the custom comparator replaces default LSP sorting, and `nosort` prevents the popup from overriding that order.
- The installed `/usr/share/nvim/runtime/lua/vim/lsp/completion.lua` filters against `filterText` when supplied, merges client results, calls the configured comparator, then invokes `complete()`. `convert` can alter display fields. Neither public callback is a batch response hook.
- LSP buffers disable native `autocomplete`; other buffers use current/window/loaded-buffer words. Terminal command buffers have a separate source and acceptance repair.
- Material already owns wheat Pmenu colors and the documentation surface. This proposal preserves those changes.

## Goals / Non-Goals

**Goals:** A precise and testable ranking policy; a public-API implementation path; syntax hints that fail neutrally; predictable menu layout; explicit word fallback.

**Non-Goals:** Replacing native completion, implementing a type checker or scope resolver, project-wide symbol indexing, learned ranking, usage persistence, new completion sources, terminal ranking changes, or automatic fallback in the first implementation.

## Decisions

### 1. Ideal ranking and the implementable first policy

Distinguish typed-text matching from surrounding-code relevance. The user specifically wants `User` on the current line to favor `createUser` over `createCat` while typing `create`. An ideal sorter combines both signals with semantic suitability, locality, server confidence, and user intent. These signals have different reliability. The first policy uses only evidence available in native completion, with a lexicographic key rather than a bag of arbitrary weights.

Priority, highest first:

| Stage | Rule | Reason |
| --- | --- | --- |
| 1 | Exact case-sensitive text; exact case-insensitive text; case-sensitive prefix; case-insensitive prefix; other fuzzy match | A matching function must beat an unrelated variable |
| 2 | Descending current-line identifier affinity within the same match class | Nearby `User` favors `createUser` over `createCat` |
| 3 | Descending native fuzzy score within the same match class | Rewards compact and boundary-aligned matches without a second fuzzy algorithm |
| 4 | Nondeprecated before deprecated | Prefer supported APIs when textual relevance ties |
| 5 | Single enabled LSP client: ascending `sortText`, falling back to label | Retains server semantic preferences within equal textual relevance |
| 6 | Confident syntax fit before neutral fit | A weak hint; never excludes a candidate |
| 7 | Ordinary items before snippet-kind items | Keeps snippets available without the current unconditional last-place rule |
| 8 | Case-folded label, original label, stable provider identity, canonical insertion/edit identity | Repeatable order for distinguishable items |

Typed-match class comes first; current-line affinity comes before fine fuzzy score so the shorter `createCat` cannot win merely on compactness. Later stages break ties in those relevance signals. A uniquely exact deprecated item or snippet still beats a weak fuzzy ordinary item. No universal variables-before-functions policy remains. Ordinary kinds have equal default priority. Empty prefix gives every item the same text class and score; do not call the fuzzy matcher on it. Missing kind, tags, `sortText`, and optional fields must not throw.

For more than one enabled completion client, omit stage 5 for the ENTIRE snapshot. `sortText` is meaningful within a server's list; unrelated servers need not share a scale. Never conditionally compare `sortText` only when a pair has the same client: that can create A<B, B<C, C<A cycles. A future batch adapter could normalize per-provider ranks, but `cmp` alone cannot see the whole result set. The conservative initial policy sacrifices some server ordering in multi-client buffers for a transitive comparator.

Stable provider identity is server name plus root, with runtime client ID as a collision fallback. Canonical insertion identity includes word, edit range/text, snippet format, and additional edits; different actions sharing a label remain separate. Fully equivalent entries can compare equal. Do not resolve or deduplicate items inside the comparator.

Examples:

- Line `const user: User = create`, query `create`: `createUser` precedes `createCat`.
- Even near `User`, query `createCat` keeps exact `createCat` above `createUser`.
- Query `print`: function `print` precedes variable `printOptions`.
- Query `pri`: exact variable `pri` precedes function `print`.
- Equal text score and distinct server keys: server preference wins over a local syntax guess.
- Equal text score and server key in a confirmed type position: class/interface/type parameter can precede a variable.
- An exact snippet remains above a weakly matching nonsnippet.
- In unknown context, fields and methods receive the same syntax score.

Deferred ideal signals: local declaration distance, lexical scope membership, expected return/argument type, server `preselect`, recent acceptance, and frequency. Completion kind does not expose these reliably. Do not invent locality by scanning documentation or infer type compatibility from identifier spelling.

### Current-line identifier affinity

Extract identifier words from the current line, excluding the active completion replacement span. Split candidate names and line identifiers at camelCase, PascalCase/acronym, snake_case, and digit boundaries, then case-fold whole words. Exclude words already present in the typed query and a small documented language-keyword list. Count distinct shared words, not substring occurrences or repeated mentions. Thus `User` matches `createUser` and `create_user`, but does not match `abuser`. No stemming, plural inference, semantic synonym guessing, or comment/documentation scanning is introduced.

Use identifier syntax spans where a usable tree exists, excluding comments and string literals. Without a usable tree, return zero line affinity rather than guessing whether quoted or commented text is code. Restrict scanning to the current line; no surrounding-line window or buffer-wide frequency score. Compute the line token set once per snapshot and candidate token sets once per item. A current-line edit invalidates affinity even when the typed prefix stays unchanged. The signal is lexical context, not proof of type compatibility.

### 2. Native callback implementation

Keep `vim.lsp.completion.enable`, `cmp`, `convert`, native acceptance, and `fuzzy,nosort,noselect`. Put ranking and syntax classification in one small module; keep source orchestration and mappings in `configs/completion.lua`.

Use an immutable snapshot for each synchronous sort: buffer, changedtick, cursor, enabled-client count, completion base, current-line identifier words, and syntax classification. The first comparator call can establish it; reuse it while these inputs are unchanged. Cache decorated item keys in a weak-key table under that snapshot. A comparator only compares prepared keys: no LSP request, parser traversal, full-buffer scan, or mutable recency update during comparisons. Snapshot invalidation must include edits, cursor moves, attach/detach, and buffer switches; do not use a lifetime cache.

Recompute fuzzy scores with public `matchfuzzypos` on `filterText` or label and the applicable typed base. The runtime currently exposes `_fuzzy_score`, but that private field is not the implementation contract. Respect native eligibility; do not resurrect rejected items. Preserve case behavior and test Unicode and empty bases.

Completion bases can differ from the keyword before the cursor: punctuation, server text-edit ranges, UTF-16 positions, and qualified names matter. Start with the current keyword base, and derive a candidate-specific base from a valid edit start when needed using the client's encoding and public conversion APIs. If the base cannot be established safely, assign neutral text relevance for the entire ambiguous comparison group; preserve native eligibility and insertion data. Do not rank a method using the whole `object.` receiver as its query. A focused fixture spike must settle these base cases before switching the active comparator.

### 3. Tree-sitter tells syntax, LSP supplies semantics

Use `vim.treesitter.get_node` and a bounded ancestor walk against an available parser. Check the cursor position and preceding byte-aware token position because completion often happens in an incomplete or missing node. Use the active injected language when identifiable; otherwise return unknown. Never classify by matching arbitrary node-name substrings across all grammars.

Initial grammar adapters: Lua and TypeScript/TSX. Other filetypes remain neutral until they have fixtures. Explicit classifications:

| Context | Allowed syntax preference | Limit |
| --- | --- | --- |
| Confirmed type position in TypeScript | Class, interface, struct, enum, type parameter | Cannot prove expected type compatibility |
| Lua `receiver:` method position | Method and function kinds | Cannot prove receiver type or callability of a field |
| Generic `receiver.` member access | Member kinds as a group, no fields-versus-methods preference | Server normally already filters members |
| Import/module path | Module, file, folder kinds where applicable | Do not suppress server path/string items |
| Ordinary expression/call arguments | Neutral | A call argument is not necessarily another function |
| Comment, general string, unknown grammar | Neutral | Do not suppress LSP doc tags or path completions |

Missing parser, malformed tree around the relevant construct, unsupported node, or ambiguous injection gives unknown. Do not reject all hints merely because an unrelated part of the file has an error. No parser installation, parser setup, or whole-buffer parse belongs inside sorting. If there is no current usable tree, use neutral ranking. Fixtures must cover incomplete `obj.`/`obj:`, valid surrounding constructs, and missing/error nodes.

The syntax stage intentionally comes after server ordering in the single-client case. It will sometimes have no effect when a server assigns unique keys; moving it earlier would be a distinct ranking policy change, not a silent tuning tweak.

### 4. Menu presentation changes display only

Set `pumheight=10`, `pummaxwidth=70`, retain the default `abbr,kind,menu` order, rounded border, and opaque wheat surfaces. The renderer may shrink to fit a small screen.

Use `convert` to return only display overrides: a single-line `abbr` bounded to 45 display cells and single-line `menu` bounded to 24 cells. Prefer the server label as the name; keep signature/module detail in the secondary column or documentation. Truncate with a Unicode-safe ellipsis measured by display width. Avoid regex removal of parentheses, which can change valid operator names and labels. Retain native kind labels initially; icons are optional follow-up polish.

Never override `word`, `user_data`, `textEdit`, `additionalTextEdits`, snippet format, commands, or native deprecated styling. Native acceptance must still insert full text, expand snippets, and apply auto-imports. Display truncation is not deduplication.

### 5. Buffer words: explicit fallback first

Add an insert-mode `<C-x><C-n>` mapping through `mappings.map` that explicitly starts native keyword completion using the configured current/window/loaded-buffer sources, including in LSP buffers. If a popup is open, cancel it before switching sources. Keep `<C-Space>` as LSP/manual completion and retain current accept/newline rules. Test the sequential mapping through langmapper; do not assume remapping a native multi-key sequence is conflict-free.

Why manual initially: `cmp` is never invoked for a zero-item list; `convert` sees one candidate at a time. A timer after triggering LSP cannot distinguish empty results from slow results reliably. `CompleteDone` is an acceptance/cancellation event, not a completion-response event. Automatic fallback requires ownership of response aggregation, pending-client completion, cancellation, incomplete-result refresh, and acceptance metadata, or a future public native hook. It is not hidden in the ranking work.

### 6. Implementation options

| Option | Effort and trade-off | Decision |
| --- | --- | --- |
| Remove custom `cmp`, remove `nosort`, use native fuzzy sorting | Smallest change; runtime owns fuzzy/server order; no explicit context policy | Useful control baseline, not the target |
| Public `cmp` + display `convert` + bounded context adapter | Moderate config change; native LSP side effects retained; no whole-list normalization or empty-response hook | Recommended implementation |
| Custom request/source aggregator feeding `complete()` | Allows normalized server ranks and automatic fallback; must reproduce native resolve, imports, snippets, cancellation, and stale-response handling | Defer until native hooks demonstrably cannot meet a separate requirement |
| Patch Neovim or depend on private `_convert_results` / `_fuzzy_score` | Tight runtime coupling and upgrade cost | Rejected |
| Restore Blink or another engine | Mature source aggregation and scoring, but changes the user's native direction | Outside this proposal |

## Risks / Trade-offs

- [Text relevance can override a server's semantic order] → Document the precedence; compare fixture results with unmodified native sorting before rollout.
- [Different edit starts produce incomparable bases] → Test encoding/range fixtures; neutralize ambiguous groups rather than guessing.
- [Lua `table.sort` is unstable and pair-dependent rules can cycle] → Compare immutable tuple keys and verify strict weak ordering over triples and shuffled inputs.
- [Syntax trees lag or contain errors during typing] → Bounded reads, explicit adapters, neutral fallback, no hard filtering.
- [Fuzzy scoring every comparison is expensive] → Compute each candidate key once per snapshot; profile 1,000 items. Target under 10 ms added ranking work on this machine; no cross-machine timing assertion in CI.
- [Multi-client mode omits server order] → Explicit conservative behavior; no pretend shared `sortText` scale.
- [Manual fallback requires a keypress] → Document it clearly; automatic fallback remains a separate lifecycle change.

## Migration Plan

1. Capture current behavior and native-default comparison fixtures; add rank/context and acceptance fixtures.
2. Implement pure ranking and small grammar adapters behind the existing `cmp` seam. Switch only after the base/encoding and comparator-law checks pass.
3. Add display bounds and explicit fallback through the current mapping wrapper. Update README.
4. Validate live Lua and TypeScript sessions, an unsupported-language session, terminal command input, and a floating input. Check wheat surfaces and unchanged acceptance behavior.
5. Roll back by restoring the completion module and its integration to their prior revision. Do not revert the already-applied Material wheat theme. No stored data migration is required.

## Sources

- Installed Neovim 0.12.6 runtime: `lua/vim/lsp/completion.lua` (matching, conversion, merged sort, acceptance) and `doc/{lsp,options,treesitter,insert}.txt`.
- [Native LSP completion API](https://neovim.io/doc/user/lsp/#vim.lsp.completion.enable()) — public `cmp` and `convert` hooks. Online docs may track a different version; installed runtime governs compatibility.
- [Tree-sitter integration](https://neovim.io/doc/user/treesitter/) — syntax node inspection, parsers, injections, and query facilities.
- [LSP completion item specification](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#completionItem) — server ordering, filtering, edits, and item metadata.
