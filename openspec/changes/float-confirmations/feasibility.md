# Feasibility result

Historical probe: the user subsequently approved replacing the native UI
approach with a direct Lua `vim.fn.confirm` override. The failure below does not
block that revised implementation. See `design.md` for the implemented approach.

## Outcome

The selective native-message interception gate failed on the installed Neovim `v0.13.0-dev-1988+gfacba8d36b`. No plugin implementation or configuration changes were made.

## Probe

A Python `pexpect` process launched a clean Neovim with an attached terminal at 100 columns and 30 rows. The temporary startup file installed this subscription and logged all UI events to a file:

```lua
vim.ui_attach(vim.api.nvim_create_namespace("confirm_probe"), {
  ext_messages = true,
  set_cmdheight = false,
}, function(event, ...)
  -- Log the event without consuming it.
  return false
end)
```

The terminal driver entered these commands and answered the confirmation with `n`:

```vim
:echo 'ordinary-probe'
:lua vim.g.probe_result = vim.fn.confirm('Continue?', '&Yes\n&No', 2)
```

The result was written to a temporary file after the prompt returned. A control run used the same terminal driver without attaching the UI subscription. Both `nil` and `false` callback returns were tried with the subscription enabled.

## Observations

- With no subscription, the terminal output included the ordinary echo text, confirmation message, and `[N]o` choice text.
- With the subscription, none of those strings appeared in terminal output. Ordinary command-line editing also moved to `cmdline_show` events instead of rendering in the terminal.
- Returning `false` or `nil` did not restore the TUI's built-in presentation. Leaving `cmdheight` at 1 did not prevent this change.
- The native confirmation still read `n` and returned numeric result `2` in both the subscribed and control runs. Preserved input behavior alone does not satisfy the visual requirements.
- The confirmation message arrived through `msg_show` with kind `confirm` in fast-event context. Choices arrived separately through `cmdline_show` as `(Y)es, [N]o: `.
- The prompt ended with `cmdline_hide`; this probe did not observe a corresponding `msg_clear`. Cleanup must not assume a `msg_clear` event for every confirmation.

The documented unhandled-event forwarding applies to remote UIs, not restoration of the built-in terminal renderer after enabling external message and command-line presentation.

## Scope decision required

Global native coverage through this seam would require handling ordinary message and command-line presentation too, or a separate proven integration that preserves those renderers. That exceeds the approved boundary against implementing a general message UI.

An alternative is an asynchronous `moonshine.confirm` float for local callers, leaving native and third-party prompts alone. This narrows the approved coverage and requires caller control-flow changes, so it also needs explicit approval.

Blocking float rendering, default-key cases, cancellation, multi-choice commands, third-party coverage, resize, and plugin lifecycle were not verified because the prerequisite passthrough gate failed.
