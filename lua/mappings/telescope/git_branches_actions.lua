local actions = require "telescope.actions"
local wrap_telescope_action = require "mappings.telescope_action_wrapper"

local help = function()
  local descriptions = {
    ["<cr>"] = "Switch to branch",
    x = "delete branch locally",
    m = "merge branch into current one",
    r = "rebase current branch onto selected one",
    ["?"] = "Toggle this help",
  }

  local lines = {}
  for key, _ in pairs(descriptions) do
    local desc = descriptions[key] or "Unknown action"
    table.insert(lines, string.format("%s: %s", key, desc))
  end

  -- Sort the lines for consistent output (optional)
  table.sort(lines)
  local msg = table.concat(lines, "\n")
  vim.cmd "redraw"
  vim.print(msg)
end

local keymap = {
  ["<cr>"] = wrap_telescope_action(actions.git_switch_branch),
  ["x"] = wrap_telescope_action(actions.git_delete_branch),
  ["m"] = wrap_telescope_action(actions.git_merge_branch),
  ["r"] = wrap_telescope_action(actions.git_rebase_branch),
  ["?"] = help,
}

help = function()
  local descriptions = {
    ["<cr>"] = "Switch to branch",
    d = "Diff current branch with selected one",
    x = "delete branch locally",
    m = "merge branch into current one",
    r = "rebase current branch onto selected one",
    ["?"] = "Toggle this help",
  }

  local lines = {}
  for key, _ in pairs(keymap) do
    local desc = descriptions[key] or "Unknown action"
    table.insert(lines, string.format("%s: %s", key, desc))
  end

  -- Sort the lines for consistent output (optional)
  table.sort(lines)
  local shortcuts = lines

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, shortcuts)
  vim.bo[buf].modifiable = false

  local width = vim.columns
  local height = #shortcuts

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
  })

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "?", "<cmd>close<cr>", { buffer = buf, silent = true })
end

return keymap
