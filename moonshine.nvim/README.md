# Moonshine local plugins

Each directory is a local Neovim plugin with its own `lua/` runtime. The specs
in `lua/plugins/moonshine.lua` register these directories with lazy.nvim.
They expose modules eagerly; feature initialization stays in the existing
`lua/configs/init.lua` order.

- `lua/configs/`: editor settings, plugin options, and setup calls.
- `lua/integrations/`: helpers that extend existing plugins (Neo-tree, Notify,
  Trouble, Zen-mode, and Barbar).
- `moonshine.nvim/<feature>/lua/`: feature implementations and supporting modules.
- `lua/mappings/`: bindings through `mappings.map`.
- `lua/utils/`: shared configuration helpers.
- `moonshine.nvim/utils/lua/moonshine/utils/`: shared helpers used by Moonshine
  features, exposed as `moonshine.utils.*` for features and configuration alike.

Existing modules keep their names (`debug_output`, `mini.diff`,
`native_completion`, `lsp-riced`, and others). Features extracted from configs
use `moonshine.*`, including `moonshine.git`, `moonshine.input`,
`moonshine.projects`, `moonshine.diff`, and `moonshine.markdown.*`.
Overseer extensions retain their discovery namespace. Trouble sources are
registered explicitly by `integrations.trouble` from its configuration.
Terminal buffers and command editing share the `terminal_reimagined` plugin;
command editing lives in `terminal_reimagined.command_inside_vim_editor`. Ripgrep navigation uses
`moonshine.ripgreplsp`.

`mini_animate` vendors `mini.animate` from [nvim-mini/mini.animate](https://github.com/nvim-mini/mini.animate) (MIT).
`lua/configs/minianimate.lua` disables all automatic animations.
Only the normal-mode `zz` and `zx` mappings use `integrations.mini_animate`
to animate vertical and horizontal centering. Ordinary navigation, including
`<C-d>` and `<C-u>`, stays instant.

`configs.terminal_reimagined` calls `setup()`. The terminal entrypoint creates
shells with `open_new()` and supports custom labels with `set_name()`.
`identity` owns unique names, `indicator` owns the mode bar and OSC forwarding,
and `monitor` tracks foreground processes independently of automatic naming.
`notifications` sends desktop alerts for commands observed running over one second.

`dap_tools` owns on-demand debug adapter activation. `<leader>da` ranks languages
by project marker files and previews their debuggee configurations. Several
matching languages keep the picker open after Enter so they can be activated
together. All adapter activation and presets are owned by `dap_tools`. Rust
uses CodeLLDB; Java/Scala use their LSP connections only when launching.
`<leader>dd` remains the launch picker.

`csv-render` exposes `moonshine.csv_render`. `<A-i>` in CSV/TSV opens a read-only
Unicode table in the current window; `<A-i>`, `q`, or Escape returns to the
source at the selected cell. It parses quoted delimiters, escaped quotes, and
multiline fields without depending on csvview.nvim or a Markdown parser.
Up to ten columns share the window width and wrap inside cells. Wider tables
use natural column widths capped at 40 cells, with horizontal scrolling and
window wrapping disabled (`zl` / `zh`, `zL` / `zH`). Settings live in
`lua/configs/csv.lua`. Source changes and window resizing refresh the preview;
large files render in cancellable batches.
The header stays pinned with window-local virtual lines while scrolling,
including wrapped header cells and horizontal column alignment.
Column headings are limited to five text lines, with `...` marking truncation;
data cells keep their full contents.

To add a feature, create `<feature>/lua/<module>/init.lua` here and put its
options/setup call in `lua/configs/` when needed. The local spec discovers the
new directory automatically. These plugins still use shared config helpers
and installed dependencies; they are not independent distribution packages.

Tests launched with `-u NONE` bypass lazy.nvim. Add the local runtimes before
requiring feature modules:

```lua
vim.opt.rtp:append(vim.fn.glob(root .. "/moonshine.nvim/*", true, true))
```
