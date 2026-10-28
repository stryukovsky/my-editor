local escape = require "utils.escape"
local unset = vim.keymap.del

unset("i", "<Tab>")
unset("s", "<Tab>")
unset("i", "<S-Tab>")
unset("s", "<S-Tab>")

local map = require "mappings.map"
map("n", "<C-z>", "u", { desc = "Undo" })
map("i", "<C-z>", "<C-o>u", { desc = "Undo" })

map("n", "<Esc>", escape, { desc = "clear highlights and notifications" })

map("n", "<C-c>", function()
  if vim.bo.buftype == "terminal" then
    local job = vim.b.terminal_job_id
    local ok = job and pcall(vim.api.nvim_chan_send, job, "\003")
    if not ok then
      vim.notify("Terminal job is no longer running", vim.log.levels.WARN)
    end
    return
  end
  vim.cmd "%y+"
  vim.notify("Copied whole buffer to clipboard", vim.log.levels.INFO)
end, { desc = "Interrupt terminal job or copy whole buffer" })

-- Same as i<space><Esc>l: insert a space at the cursor, stay in normal mode, move right.
map("n", "<C-space>", "i <Esc>l", { desc = "Insert space at cursor" })

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
require "mappings.git"
require "mappings.lsp_controls"
require "mappings.snippet"
require "mappings.logviewer"
require "mappings.treesj"
require "mappings.flash"
require "mappings.refresh-buffer"
require "mappings.grug-far"
require "mappings.slashing"
require "mappings.terminal"
require "mappings.override_operators"
require "mappings.ghosttycompat"
require "mappings.neovide"
require "mappings.http-runner"
require "mappings.templates"
require "mappings.visualize"
require "mappings.todotxt"
require "mappings.todo"
require "mappings.macros"
require "mappings.scenarios_of_codebase"
require "mappings.scalar_lines"
require "mappings.notify"
require "mappings.csv"
require "mappings.bigfiles"
require "mappings.zenmode"
require "mappings.help"
