# Verification

Validated on 2026-10-31 with the installed Neovim 0.12.6, Lua/TypeScript/TSX parsers, langmapper, Material theme, lua-language-server, and typescript-language-server.

## Focused proof

Run from the configuration root:

```sh
nvim --headless -u NONE -i NONE -l tests/native_completion.lua
uv run --with pynvim python tests/native_completion_integration.py
data/mason/bin/stylua --check lua/native_completion lua/configs/completion.lua tests/native_completion.lua
git diff --check
openspec validate improve-native-completion --strict
```

The Lua suite passes 211 boundary, ranking, syntax, display, and comparator-law checks. Coverage includes UTF-16 edit boundaries after emoji; filterText; exact/prefix/fuzzy precedence; current-line User affinity; comments/string/query exclusion; missing parsers; supported, unsupported, and competing injections; malformed and unrelated syntax errors; large-file flags; multi-client server-key omission; shuffled input order and transitivity; and distinct edit/data identities.

The 1,000-item profile computes exactly one key per candidate. Recent measured runs after caching/ASCII normalization changes: 7.51, 7.63, and 7.98 ms. An earlier 13.11 ms run motivated removing repeated keyword lookup and unnecessary Unicode lowercasing on ASCII names. Timing is reported, not asserted across machines. Syntax is captured by editor events; parser traversal is absent from item comparisons. Current-line identifier words are cached per base/range group; candidate keys and final edit identities are cached per snapshot.

## Running-session proof

The Python fixture drives an attached UI in a running Neovim process. All ten integration groups pass:

- TypeScript popup puts createUser before createCat near User and uses the wheat palette. Control runs with the old kind-first comparator and native-default fuzzy sorting both put createCat first.
- Fake-LSP acceptance preserves resolved documentation, native snippet placeholders, auto-import edits, completion commands, and Enter behavior.
- Same-label items remain separate with their distinct edits; Ctrl-Enter accepts the first item.
- 100 long Unicode candidates respect the 10-row/70-column limit and fit a 38-column window; Enter with no selection inserts a newline.
- English and Russian Ctrl-X/Ctrl-N sequences switch an open LSP popup to current/window/loaded-buffer words. Cancelling retains the original query; Ctrl-Space still requests LSP.
- An unsupported-language buffer uses neutral syntax preferences.
- The existing terminal source completes a path and retains native shell insertion repair.
- Default-disabled input remains disabled; typed gitcommit input retains its own snippet completion, cancellation, and suppressed documentation popup.
- The installed Lua server supplies math member completion, including sqrt.
- The installed TypeScript server completes createUser from another module and applies its real auto-import on acceptance.

Missing local language servers are reported as SKIP by the reusable fixture; both were available and passed in this run. Fake-LSP coverage runs independently of those optional local executables. pynvim is a test-only dependency, run through uv.

## Intentional limits

Syntax is a tie-breaker after applicable server ordering, not semantic type/scope inference. Unknown contexts are neutral. Current-line affinity requires usable syntax. Multiple attached completion clients omit raw server sort keys. Word fallback is explicit, not automatic after an empty response. Existing filetype-enabled floating inputs and Git commit sources remain intact.

## Rollback

Implementation baseline: commit `ca4f862`.

Restore only `lua/configs/completion.lua` and the added Native completion README section to their baseline state. Remove only these newly introduced files after removing the integration:

- `lua/native_completion/base.lua`
- `lua/native_completion/context.lua`
- `lua/native_completion/init.lua`
- `tests/native_completion.lua`
- `tests/native_completion_integration.py`

If later changes exist, revert the relevant hunks instead of restoring whole files. Leave the existing Material wheat highlights, input filetype support, input_completion.lua, Git command setup, and unrelated untracked binaries untouched. No data migration or dependency removal is needed. Reset the implementation task checkboxes if rolling back the change.
