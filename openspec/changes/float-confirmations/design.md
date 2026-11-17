# Design notes

## Approved scope revision

After the native UI feasibility gate failed, the user explicitly requested a
direct `vim.fn.confirm` override instead. The implementation therefore covers
Lua lookups of that function, not native commands or Vimscript. The original
probe findings remain in `feasibility.md` for context.

## Synchronous float

`moonshine.confirm.setup()` saves the existing Lua function and replaces it with
a synchronous implementation. It opens a non-focusable rounded scratch float,
redraws, and reads keys with `vim.fn.getcharstr()`. No nested callback migration,
UI subscription, focus change, keymap, or general message renderer is needed.
The input plugin remains unchanged.

Choices use their `&` accelerator or first character, ignoring case. The default
uses square brackets. Per the user's follow-up, a choice labeled Yes always
becomes the Enter default, even when callers request No or cancellation. This
also applies to native fallbacks. Other dialogs retain their default index, or
zero when no valid default exists. Escape and Ctrl-C return zero. The optional dialog type remains
visually unused as in the native terminal implementation.

The float wraps multiline text within editor bounds. If the complete content
cannot fit, the saved native function handles the prompt instead. Headless,
fast-event, and nested calls also delegate. Cleanup runs after normal input,
cancellation, and errors. Setup is idempotent and teardown restores the saved
function only while the plugin owns the override.

## Verification

`moonshine.nvim/confirm/tests/confirm.lua` checks real float construction with
simulated key reads, defaults, invalid keys, Unicode accelerators, wrapping,
headless/small/oversized fallback, error cleanup, and setup/teardown.

Separate attached-terminal probes exercised real keys at 100×30 and 20×12.
Cases covered Enter defaults 1/2/0, omitted default, explicit Yes/No, Escape,
Ctrl-C, multiple choices, omitted choices, and Unicode accelerators. Window,
buffer, focus, and cursor snapshots verified cleanup and preservation. Ordinary
`:echo` output remained visible. A control run compared native results for the
nine applicable ASCII cases.

On this development runtime native Ctrl-C raises a keyboard interrupt and the
tested Cyrillic accelerator did not complete the native prompt. The override
returns zero for Ctrl-C and supports the tested Cyrillic accelerator. These are
deliberate documented behaviors rather than claims of byte-for-byte native
equivalence.
