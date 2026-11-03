# Proposal

## Why

Native completion currently ranks every variable above every function, irrespective of text relevance, and has no menu size bounds. Improve relevance and readability while retaining native acceptance, documentation, snippets, and LSP edits.

## What Changes

- Prefer candidates sharing identifier words with the surrounding current line: for query `create` near `User`, rank `createUser` above `createCat`, while preserving exact-match priority.
- Replace the global kind hierarchy with a deterministic, relevance-first ranking policy, including explicit handling of server ordering, deprecated items, snippets, and multiple clients.
- Document the ideal context-aware ranking model and compare implementation options against the installed Neovim 0.12.6 APIs.
- Add conservative Tree-sitter syntax hints for initially supported languages, with neutral behavior for unknown contexts; never infer semantic scope or type compatibility from syntax alone.
- Bound the popup to 10 rows and 70 columns and shorten displayed labels without changing insertion text.
- Provide an explicit buffer-word fallback in LSP buffers. Automatic empty-result fallback is a documented future extension because the native completion API lacks a public response-transform hook.
- Preserve the existing wheat theme, terminal completion, floating input restrictions, and acceptance mappings.

## Capabilities

### New Capabilities

- `native-completion`: Relevant, readable, and predictable native completion across LSP and buffer-word sources.

### Modified Capabilities

None. No main specs exist. This change complements `prefer-native-neovim`, whose proposal preserves native completion but specifies only comment editing.

## Impact

Expected implementation: `lua/configs/completion.lua`, a small ranking/context module under `lua/`, focused headless fixtures, and README completion guidance. No completion engine plugin, external service, persistent usage database, or Neovim runtime patch is introduced. Existing Material highlight definitions remain the styling authority. This change contains planning artifacts only.
