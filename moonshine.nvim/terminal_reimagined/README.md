# terminal_reimagined

Embedded terminal creation, unique buffer names, a terminal mode bar, command
editing, and desktop notifications. Lazy.nvim discovers this local plugin;
`lua/configs/terminal_reimagined.lua` calls `setup()`.

## Configuration

All timings are milliseconds. These are the defaults:

```lua
require("terminal_reimagined").setup {
  monitor = {
    initial_delay_ms = 100, -- Wait before the first process check.
    interval_ms = 100, -- Check foreground processes this often; keep positive.
  },
  notifications = {
    min_duration_ms = 1000, -- Notify only when observed duration exceeds this.
  },
}
```

## How monitoring works

`monitor.setup()` starts one repeating libuv timer. Its callback is scheduled
onto Neovim's main loop so it can safely read buffers and update names. Calling
setup again stops and closes the old timer before replacing it. `VimLeavePre`
stops and closes the timer on exit.

Each tick checks loaded terminal buffers, including hidden and custom-named
terminals. `moonshine.utils.terminal_process_name.current()` reads the terminal
job's Linux `/proc/<pid>/stat` to find the foreground process group, then reads
its leader's command line. The waiting shell is excluded; separately launched
shell scripts and unknown executables count as commands. SSH labels can use
the connected peer address.

Every sample goes to `notifications.observe()`. This records the foreground
PID, label, and monotonic time when first observed. Once that PID disappears
from `/proc`, its tracking record is cleared. If the observed duration exceeds
`min_duration_ms`, `notify-send` sends a desktop notification through the system
notification service, including GNOME. The current buffer and application focus
do not suppress notifications. If `notify-send` is unavailable, nothing is sent.
Wiping a buffer clears its tracking record without sending a completion alert.

Automatic names update only when the process label changes. Custom labels stay
unchanged while their processes are still monitored. The tabline redraws only
when an automatic name changes.

This is foreground-process polling, not shell command completion tracking.
Timing is approximate: commands can start or finish between ticks, and duration
is measured from first observation. Commands that finish between checks can be
missed. Background jobs and shell builtins running inside the waiting shell are
not tracked separately. A pipeline is represented by its foreground group leader;
its exit can precede the remaining pipeline processes. Closing a terminal buffer
is not treated as successful command completion, and exit status is not available.

## Modules and entrypoints

- `open_new(cwd?)`: create a shell, show and pin its buffer, and enable automatic names.
- `set_name(buf, label)`: assign a unique custom name and disable automatic naming.
- `identity`: reserve unique names and release them when buffers are wiped.
- `indicator`: show terminal input/normal mode in the winbar and forward OSC
  notification requests to the host terminal. Those application-generated
  notifications are separate from process-completion notifications.
- `monitor`: sample terminal processes and update automatic names.
- `notifications`: track observed process lifetimes and send desktop alerts.
- `command_inside_vim_editor`: edit pending shell commands with completion; used by the Zsh integration.

Bindings live in `lua/mappings/terminal.lua`: `<leader>tn` opens a terminal,
`<leader>tr` renames a buffer, `<leader>ex` runs the current Bash/Python script,
and terminal `<C-s>` invokes the shell's pending-command editor integration.
