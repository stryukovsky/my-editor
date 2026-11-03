# Moonshine local plugins

Each directory is a local Neovim plugin with its own `lua/` runtime. The specs
in `lua/plugins/moonshine.lua` register these directories with lazy.nvim.
They expose modules eagerly; feature initialization stays in the existing
`lua/configs/init.lua` order.

- `lua/configs/`: editor settings, plugin options, and setup calls.
- `lua/integrations/`: helpers that extend existing plugins (Neo-tree, Notify,
  Trouble, Zen-mode, CSV viewing, and Barbar).
- `moonshine.nvim/<feature>/lua/`: feature implementations and supporting modules.
- `lua/mappings/`: bindings through `mappings.map`.
- `lua/utils/`: shared configuration helpers.

Existing modules keep their names (`debug_output`, `mini.diff`,
`native_completion`, `lsp-riced`, and others). Features extracted from configs
use `moonshine.*`, including `moonshine.git`, `moonshine.input`,
`moonshine.projects`, `moonshine.diff`, and `moonshine.markdown.*`.
Overseer extensions retain their discovery namespace. Trouble sources are
registered explicitly by `integrations.trouble` from its configuration.
Terminal buffers and command editing share the `terminal_reimagined` plugin;
command editing lives in `terminal_reimagined.command`. Ripgrep navigation uses
`moonshine.ripgreplsp`.

To add a feature, create `<feature>/lua/<module>/init.lua` here and put its
options/setup call in `lua/configs/` when needed. The local spec discovers the
new directory automatically. These plugins still use shared config helpers
and installed dependencies; they are not independent distribution packages.

Tests launched with `-u NONE` bypass lazy.nvim. Add the local runtimes before
requiring feature modules:

```lua
vim.opt.rtp:append(vim.fn.glob(root .. "/moonshine.nvim/*", true, true))
```
