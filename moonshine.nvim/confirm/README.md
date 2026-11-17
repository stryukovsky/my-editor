# Floating confirmations

`require("moonshine.confirm").setup()` replaces Lua's `vim.fn.confirm` with a
centered rounded float. Calls stay synchronous and return the selected choice's
one-based index, or `0` on Escape/Ctrl-C. Enter always selects Yes when a choice
is labeled Yes, overriding the caller's default (including `0`). This also
applies to native fallbacks. Other dialogs keep the caller's default (choice 1
when omitted); their default of `0` makes Enter cancel.

Choice accelerators use the character after `&`, or the first character when
there is no `&`. Matching ignores case. The default appears in square brackets;
other accelerators appear in parentheses. Multiline messages wrap to fit.

The float never takes focus or changes the source buffer, cursor, or mode.
No message UI subscription or input-plugin changes are involved.

The override covers Moonshine and third-party **Lua** callers looking up
`vim.fn.confirm` after setup. It does not affect native `:confirm`, Vimscript
calls, `vim.call("confirm", ...)`, or previously captured function references.
Dialog type arguments are accepted but have no visual effect, like the terminal
version of native confirmation.

Headless calls, fast-event calls, nested dialogs, and dialogs too large for the
current editor use the saved native implementation. Large prompts are not
truncated. Setup is idempotent; `require("moonshine.confirm").teardown()` restores
the original Lua function when this plugin still owns the override.

## Verification

From the repository root:

```sh
nvim --clean --headless -l moonshine.nvim/confirm/tests/confirm.lua
```

The regression checks exercise real scratch windows with simulated keys. They
cover choices, defaults, wrapping, cleanup, fallback, and setup/teardown. Attached
terminal checks additionally exercised real keystrokes and ordinary message
rendering at 100×30 and 20×12.
