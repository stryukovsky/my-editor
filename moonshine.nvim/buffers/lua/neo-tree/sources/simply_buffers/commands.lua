local M = {}
local common = require "neo-tree.sources.common.commands"
local utils = require "neo-tree.utils"
local buffers = require "moonshine.buffers"

local function yank_names(nodes)
  local names = {}
  for _, node in ipairs(nodes) do
    local name = node.extra and node.extra.plain_name
    if name then
      names[#names + 1] = name
    end
  end
  if #names > 0 then
    vim.fn.setreg("+", table.concat(names, "\n"), #names > 1 and "l" or "c")
  end
end

function M.open(state)
  local node = state.tree and state.tree:get_node()
  local buf = node and node.extra and node.extra.bufnr
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local win, is_tree = utils.get_appropriate_window(state)
  vim.api.nvim_set_current_win(win)
  if is_tree then
    vim.cmd "vsplit"
  end
  vim.api.nvim_set_current_buf(buf)
end

function M.refresh(state)
  require("neo-tree.sources.simply_buffers").navigate(state)
end

function M.yank_names(state)
  yank_names { state.tree:get_node() }
end

function M.yank_names_visual(_, selected_nodes)
  yank_names(selected_nodes or {})
end

function M.close_buffer(state)
  local node = state.tree and state.tree:get_node()
  local buf = node and node.extra and node.extra.bufnr
  if buf then
    buffers.close_buffer(buf)
  end
end

function M.close_unprotected()
  buffers.close_unprotected()
end

common._add_common_commands(M)

return M
