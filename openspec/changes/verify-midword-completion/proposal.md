# Proposal

## Why

The current completion checks exercise acceptance primarily at the end of a word. Completion before an existing suffix needs explicit proof that text is not duplicated, edit boundaries are respected, snippets still work, and Cyrillic text remains intact.

## What Changes

- Add focused acceptance cases for identical existing suffixes, ordinary LSP text edits, insert/replace ranges, snippets, and Cyrillic text.
- Establish results with both unmodified native LSP completion and this config's completion integration on the installed Neovim version.
- Define safe suffix reuse without deleting unrelated text or overriding intentional server edit boundaries.
- Add a narrowly scoped correction only for a reproducible failure of the specified behavior. A fully passing native path requires tests and documentation only.
- Preserve existing ranking, display formatting, acceptance mappings, auto-imports, and source restrictions.

## Capabilities

### New Capabilities

- `midword-completion`: Predictable completion acceptance around existing text after the cursor, including edit ranges, snippets, Unicode, and cancellation.

### Modified Capabilities

None. `openspec list --specs` reports no published specs. This capability complements the pending `improve-native-completion` change's `native-completion` requirements without changing its ranking policy.

## Impact

- Primary work: focused fake-LSP/UI fixtures in `tests/native_completion_integration.py`, or a separate focused fixture if that keeps the existing harness simpler.
- Conditional implementation: `lua/configs/completion.lua` and a small helper only if a failing case proves it necessary. `lua/native_completion/base.lua` is relevant only if evidence identifies a base/encoding defect.
- Documentation: README completion guidance and a verification record in this change directory, including actual Neovim version and baseline results.
- No new plugin, custom LSP aggregator, runtime patch, snippet source, ranking change, or general terminal/gitcommit path rewrite. Preparing this proposal does not implement or claim verification of the behavior.
