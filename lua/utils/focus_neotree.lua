-- Focus a Neo-tree source, retrying after competing UI updates.
local neotree_command = require "neo-tree.command"

local function cursor_in_neotree()
  local win = vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree"
end

return function(source, needs_reveal, opts)
  pcall(function()
    local focus_command = vim.tbl_extend("error", {
      action = "focus", -- Focus NeoTree
      source = source,
      position = "left", -- Or "left", "float"
    }, opts or {})
    neotree_command.execute(focus_command)
    vim.defer_fn(function()
      if needs_reveal then
        local reveal_command = vim.tbl_extend("error", {
          action = "reveal", -- Focus NeoTree
          source = source,
          position = "left", -- Or "left", "float"
        }, opts or {})
        neotree_command.execute(reveal_command)
      end
      neotree_command.execute(focus_command)
      vim.defer_fn(function()
        if not cursor_in_neotree() then
          neotree_command.execute(focus_command)
        end
      end, 200)
    end, 100)
  end)
end
