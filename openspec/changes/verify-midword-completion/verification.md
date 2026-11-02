# Verification

Verified on 2026-11-02 with `NVIM v0.13.0-dev-1988+gfacba8d36b`.
The earlier README target of 0.12.6 was not the installed binary; README now
states the actual verified version.

## Baseline and diagnosis

The new fake-LSP/UI fixture runs an isolated native control without this
config's callbacks, followed by the configured integration and actual acceptance
mappings. Before the correction, both modes showed the same gaps: native
completion inserted the full candidate before an existing suffix and did not
consume the part of a server edit range after the cursor. Snippet expansion
also left that suffix behind. This was an insertion issue, not a ranking-base
or Unicode-conversion defect in `native_completion/base.lua`.

The native control confirms that differing `InsertReplaceEdit` ranges use
**insert** on this runtime. An explicit range ending at the cursor intentionally
keeps the following text, even if its spelling repeats part of the inserted word.

Reproduction and proof:

```sh
uv run --with pynvim python tests/native_completion_midword.py --observe --json /tmp/midword-results.json
uv run --with pynvim python tests/native_completion_midword.py
```

`--observe` permits configured gaps for baseline investigation. Normal execution
requires every configured case to pass; native-control gaps remain visible as
`GAP` lines because that mode deliberately excludes the correction. Optional
JSON records the binary version, exact original lines/cursor, candidate, LSP
item/ranges, encoding, final marked text/cursor, snippet state, and commands.

## Acceptance matrix

`|` marks the insertion cursor. Native results below also match the configured
results measured before the correction. All 18 configured cases pass afterward.

| Case | Native control | Configured result |
| --- | --- | --- |
| `pri\|nt(value)`, plain `print` | `print\|nt(value)` | `print\|(value)` |
| `\|print(value)`, manual plain completion | `print\|print(value)` | `print\|(value)` |
| Different suffix `pri\|Other` | `print\|Other` | Same; unrelated text retained |
| Longer suffix `pri\|ntOther` | `print\|ntOther` | Same; no partial overlap inference |
| Type `n` while the menu for `pri\|nt(value)` is open | `print\|nt(value)` | Same; updated query has no exact remainder match |
| Full-word `TextEdit` | `print\|nt(value)` | `print\|(value)` |
| Cursor-ended `TextEdit` | `print\|nt(value)` | Same; outside-range suffix retained |
| Distinct insert/replace ranges | `print\|nt(value)` | Same; native insert policy retained |
| Inherited full-word edit range | `print\|nt(value)` | `print\|(value)` |
| Full-word snippet, edit placeholder and jump to `$0` | `call(item)\|l;` | `call(item)\|;` |
| Cyrillic `при\|вет()` | `привет\|вет()` | `привет\|()` |
| Full-word range after Cyrillic/emoji, UTF-8 | Leaves `nt` | Removes only ranged suffix; surrounding Unicode unchanged |
| Same range with negotiated UTF-16 | Leaves `nt` | Same correct text and byte cursor as UTF-8 |
| Cancel a selected command-bearing item | Original `pri\|nt(value)` | Original text; no command executed |
| Full-word edit plus import and command | Import/command once; leaves `nt` | `-- import` and `print\|(value)`; import/command once |
| Explicit first-item acceptance | Leaves `nt` | `print\|(value)` through configured Ctrl-Enter |
| Undo plain acceptance | Original text restored | Original text restored |
| Undo ranged acceptance | Original text restored | Original text restored |

Every accepted non-undo case asserts the complete marked buffer, including byte
cursor position. The snippet case additionally asserts active placeholder state
before typing `item`. Undo cases create a boundary with `<C-g>u` immediately
before manual completion, then use `<Esc>u` once; both modes restore the exact
original buffer. No separate suffix-repair undo step is introduced.

## Correction and isolation

`native_completion/midword.lua` records unselected popup input through the public
`CompleteChanged` event. Its global `CompleteDone` callback is registered before
native buffer-local acceptance callbacks, consumes the pending snapshot once,
and deletes only the proven suffix before native snippet/import/command effects.
The deletion joins the accepted word's undo block.

Checks include intentional acceptance, ordinary enabled buffer, matching buffer
and window, originating row, exact expected inserted text, and unchanged suffix.
Leaving the buffer, window, or Insert mode clears the snapshot. Explicit ranges
are converted with the negotiated encoding; plain inference requires an exact
identifier prefix and entire identifier remainder. Snippets never use plain
inference. No request, delayed edit, private API, runtime patch, metadata rewrite,
ranking change, or new keymap is introduced.

## Existing gates

All passed:

- `nvim --headless -u NONE -i NONE -l tests/native_completion.lua`: 199 boundary,
  ranking, syntax, display, and comparator checks.
- `uv run --with pynvim python tests/native_completion_integration.py`: native
  resolve/docs, snippets, imports, commands, distinct same-label actions, popup
  bounds, English/Russian fallback, terminal insertion, typed inputs, and installed
  Lua/TypeScript/Go server checks.
- `uv run --with pynvim python tests/native_input_completion.py`: popup rendering,
  snippet/input acceptance, changed-file/folder acceptance, and delay restoration.
- `nvim --headless -u NONE -i NONE -l tests/input_completion.lua`: changed paths,
  parent folders, nested cwd, renames, detached HEAD, and non-Git input.
- `stylua --check lua/configs/completion.lua lua/native_completion/midword.lua`.
- `git diff --check` and strict OpenSpec validation.

No required matrix case remains unresolved. Runtime compatibility beyond the
binary above has not been established by this verification.

## Follow-up: command-area messages while typing

The reported “Pattern not found” appears in Neovim's message area while typing
code. The config did not set `shortmess` flag `c`, which Neovim documents as
suppressing native completion messages, including this exact text. Completion
now appends `cC` to suppress status and scanning notices while preserving errors.
The isolated UI fixture did not reproduce the reported message before this
option change; the suppression targets the documented native message path.

`uv run --with pynvim python tests/native_completion_typing.py` passes. It
observes both UI message events and rendered grid frames, exercises repeated
manual no-match requests and ordinary automatic typing, and types `pri` letter
by letter before `nt(value)` with automatic LSP completion. Every letter opens
a popup; acceptance produces `print(value)` at byte cursor column 5 without a
manual trigger. This covers a typing path the earlier manual acceptance matrix
did not exercise. The 18-case midword matrix also passes after the option change.
