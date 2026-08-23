local clear_selections = require "utils.clear_selections"
local unset = vim.keymap.del

unset("i", "<Tab>")
unset("s", "<Tab>")
unset("i", "<S-Tab>")
unset("s", "<S-Tab>")

local map = require "mappings.map"
map("n", "<Esc>", clear_selections, { desc = "general clear highlights" })

map("n", "<C-c>", function()
  if vim.bo.modifiable then
    vim.cmd "%y+"
    vim.notify("Copied whole buffer to clipboard", vim.log.levels.INFO)
  else
    vim.notify("Buffer is not editable. Cannot copy.", vim.log.levels.WARN)
  end
end, { desc = "Copy whole file if buffer is editable" })

local termux_version = os.getenv "TERMUX_VERSION"
if not termux_version then
  require "mappings.yanky"
end

require "mappings.lspconfig"
require "mappings.dap"
require "mappings.ui-components"
require "mappings.search"
require "mappings.minidiff"
require "mappings.yank_position"
require "mappings.multicursor"
require "mappings.navigation"
require "mappings.projects"
require "mappings.tine-code-action"
require "mappings.ui-components"
require "mappings.markdownpreview"
require "mappings.inspection"
require "mappings.ripgreplsp"
require "mappings.neotest"
require "mappings.text-case"
require "mappings.refactoring-setup"
require "mappings.neogit-setup"
require "mappings.lsp_controls"
require "mappings.llm"
require "mappings.snippet"
require "mappings.logviewer"
require "mappings.grapple"
require "mappings.treesj"
require "mappings.disable_macros"
require "mappings.flash"
require "mappings.aidviser"
require "mappings.substitute"
require "mappings.slashing"
require "mappings.terminal"
require "mappings.override_operators"
require "mappings.ghosttycompat"
require "mappings.neovide"
require "mappings.http-runner"
require "mappings.templates"
require "mappings.plantuml"
require "mappings.todotxt"
require "mappings.todo"
require "mappings.macros"
require "mappings.notify"
require "mappings.csv"
require "mappings.bigfiles"
require "mappings.zenmode"
