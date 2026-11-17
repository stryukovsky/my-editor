# Floating confirmations

## Why

Lua Yes/No confirmations still appear in Neovim's command area while text input
already uses a centered rounded floating window. A small local Moonshine plugin
should provide the same visual treatment without changing synchronous callers.

## Changes

- Add `moonshine.nvim/confirm/` exposing `moonshine.confirm`, configured through `lua/configs/confirm.lua`.
- Override Lua's `vim.fn.confirm` directly, as explicitly requested after the native UI feasibility probe failed.
- Display messages and choices in a centered rounded float matching the existing input's visual conventions.
- Keep synchronous numeric choice results and existing caller control flow. Support multiple choices, accelerators, Enter defaults, and cancellation.
- Use native fallback for headless calls or prompts that cannot fit safely. Keep setup idempotent and provide teardown.
- Leave native command presentation, general messages, and existing text input unchanged.

## Acceptance

- Lua Moonshine and third-party callers resolving `vim.fn.confirm` after setup receive the float without caller changes.
- Explicit choices return their one-based index. Enter always selects Yes when present, overriding caller defaults including 0. Other dialogs retain their original defaults.
- Escape and Ctrl-C return 0 without approving an action.
- Multiline messages wrap and multi-choice prompts retain their choices and accelerators.
- Repeated prompts and input errors leave no stale windows or buffers. Focus and cursor remain on the source window.
- Headless calls and oversized prompts delegate to the saved native implementation.
- Ordinary messages and command-line editing remain native. Existing floating input is not modified.
- Setup is safe to repeat and teardown restores the saved function.

## Out of scope

- Native `:confirm`, Vimscript, `vim.call("confirm", ...)`, and previously captured function references.
- Restyling notifications, command-line input, or arbitrary plugin picker windows.
- General message UI interception or asynchronous caller migrations.
- Changing the existing floating input plugin or adding dependencies.
