local M = {}
local identity = require "terminal_reimagined.identity"
local indicator = require "terminal_reimagined.indicator"
local zsh_available

M.set_name = identity.set_name
M.mode_label = indicator.mode_label

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", {
    monitor = { initial_delay_ms = 100, interval_ms = 100 },
    notifications = { min_duration_ms = 1000 },
  }, opts or {})
  identity.setup()
  indicator.setup()
  require("terminal_reimagined.notifications").setup(opts.notifications)
  require("terminal_reimagined.monitor").setup(opts.monitor)
end

--- Show and pin a terminal buffer using the shared terminal identity rules.
---@param buf integer
local function show(buf)
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = true
  vim.api.nvim_set_current_buf(buf)
  vim.cmd.BufferPin()
  vim.b[buf].terminal_auto_name = true
  vim.b[buf].terminal_process_label = nil
  local label = require("moonshine.utils.terminal_process_name").current(
    vim.b[buf].terminal_job_pid
  ) or "Terminal"
  identity.set_auto(buf, label)
end

--- Open a pinned Neovim terminal in the current window, like `<leader>tn`.
---@param cwd? string working directory for the new shell
---@return boolean
function M.open_new(cwd)
  if cwd and cwd ~= "" then
    local stat = vim.uv.fs_stat(cwd)
    if not stat or stat.type ~= "directory" then
      vim.notify("Cannot start terminal: not a directory", vim.log.levels.WARN)
      return false
    end
    vim.cmd("lcd " .. vim.fn.fnameescape(cwd))
  end
  if zsh_available == nil then
    zsh_available = vim.fn.executable "zsh" == 1
  end
  -- :terminal uses :enew, which can reuse an empty, modified buffer.
  -- Start in a fresh scratch buffer and keep the previous buffer's edits.
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_call(buf, function()
    vim.fn.jobstart({ zsh_available and "zsh" or "bash" }, { term = true })
  end)
  show(buf)
  return true
end

return M
