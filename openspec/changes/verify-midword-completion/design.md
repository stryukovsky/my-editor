# Design

## Context

See proposal.md for motivation. `configs/completion.lua` enables native LSP completion with ranking and display callbacks; `native_completion/base.lua` derives ranking bases using byte offsets and negotiated position encoding. Ranking does not own insertion. Terminal command completion and gitcommit inputs have separate acceptance paths.

The existing fake-LSP integration harness checks snippets, imports, resolved documentation, commands, and acceptance keys, but does not provide a dedicated midword matrix. The installed binary currently reports `NVIM v0.13.0-dev-1988+gfacba8d36b`; the README names 0.12.6. Verification must record the actual binary rather than assume that documentation describes the executable.

The local compl.nvim checkout is an idea reference only. Its suffix handling compares text after the cursor and mixes display widths with string offsets; copying it would not establish correctness for our native path.

## Goals / Non-Goals

**Goals:** Reproducible exact-text and cursor assertions; clear separation of accidental overlap from intentional edit boundaries; a test-only outcome when native completion already satisfies the contract.

**Non-Goals:** A new completion engine, response aggregation, learned ranking, snippet catalog, broad word-replacement policy, runtime patch, changes to terminal/gitcommit insertion, or independent keymap changes.

## Decisions

### 1. Run a native control before choosing implementation

Extend the fake-LSP harness with explicit fixture modes and reproducible cursor placement. Run equivalent cases with:

1. Native `vim.lsp.completion.enable()` without our comparator, converter, or config acceptance callbacks.
2. The current configured integration and its actual mappings.

Use isolated buffers and undo histories. Capture exact pre/post lines, byte cursor positions, selected candidate, advertised encoding, edit ranges, snippet state, and emitted command events. Select items deliberately; do not depend on ranking the target first. Test standard Enter acceptance and the existing explicit first-item shortcut. Keep fake-server cases mandatory and deterministic; live language servers are optional corroboration.

Record results in `verification.md` with the Neovim version, commands, expected outputs, and native/configured pass/fail columns. A native failure is evidence to investigate, not proof that the config caused it. Passing cases require no production change.

### 2. Give explicit edits priority over overlap inference

The spec distinguishes plain identifiers without a range from server-authored edits. For a plain candidate, the only reusable suffix is an immediately adjacent, exact match to the candidate's entire untyped remainder. Require an unambiguous prefix relationship and valid character boundaries; do not apply this heuristic to snippets, multiline replacements, or arbitrary fuzzy substitutions.

For an explicit `TextEdit`, apply the stated range, including its end. For `InsertReplaceEdit`, preserve the runtime's native choice of insert versus replace: the fixture records that choice and asserts its precise result. Do not introduce a new insert/replace mode. Inherited list edit ranges count as explicit edits. Preserve unmatched text, punctuation, and text outside the effective range even when the resulting spelling looks repetitive.

An unconditional delete-to-end-of-word hook is rejected: it would silently expand server edit ranges and damage unrelated text. A display converter is also not an insertion hook; it must continue to return presentation fields only.

### 3. Make correction conditional on a failing fixture

First localize any failure to range application, plain overlap, snippet acceptance, or ranking-base conversion. Fix only the responsible config layer and retain the failing case as regression proof. Keep native ownership of snippet expansion, additional edits, commands, and resolution; do not add a second LSP side-effect handler.

Prefer a supported native option or public API before adding an acceptance helper. If a helper is unavoidable, constrain it to the proven ordinary-buffer LSP case, intentional acceptance, original buffer, unchanged surrounding context, and valid byte boundaries. Its own edits must not create an extra undo step. Do not attach it to terminal or floating input sources. Any mapping needed to reach an existing operation must use `mappings.map`.

If the only apparent solution requires private runtime hooks or patching Neovim, record the minimal reproducer and limitation and leave the affected requirement unresolved. Do not silently broaden the architecture or call a failing requirement complete.

### 4. Treat Unicode and acceptance side effects as part of correctness

Cover ASCII and Cyrillic identifiers; Cyrillic and emoji before the edit distinguish byte offsets from UTF-16 units. Negotiate UTF-8 and UTF-16 explicitly in separate fake-server modes and assert the exact resulting cursor byte offset. Use supported position conversion APIs, never display width for buffer columns.

Snippet cases use a full-word range, an active placeholder, a placeholder edit, and a jump to `$0`. Also verify cancellation, imports, commands, undo, and no duplicate post-acceptance application. Re-run existing terminal/input checks if acceptance orchestration changes.

## Risks / Trade-offs

- [Runtime behavior differs between releases] → Record actual version and native insert/replace choice; document the verified runtime without claiming untested compatibility.
- [Overlap inference deletes intentional text] → Restrict inference to exact plain-identifier remainder matches with no explicit range.
- [A hook duplicates native edits or races a later context] → Keep native side effects authoritative, validate buffer/context, and exercise cancellation and buffer-switch cases when adding asynchronous code.
- [A fix breaks undo grouping] → Compare isolated native/configured undo sequences and require restoration of the original text without repair leftovers.

## Rollout and rollback

Land focused proof and verification results first. Add production changes only for demonstrated gaps, then run the affected completion gates. Document any user-visible correction in README alongside the verified runtime. Rollback removes only the optional correction and its wiring; retain useful fixtures and recorded baseline evidence.
