local map = require "mappings.map"

local M = {}

-- Run after Neo-tree installs its defaults. Read the live global mappings so
-- aliases also cover new <leader>g bindings without maintaining a second list.
function M.attach(state)
  if
    state.name ~= "git_status"
    or not state.bufnr
    or not vim.api.nvim_buf_is_valid(state.bufnr)
  then
    return
  end
  local prefix = vim.api.nvim_replace_termcodes(
    (vim.g.mapleader or "\\") .. "g",
    true,
    true,
    true
  )
  for _, binding in ipairs(vim.api.nvim_get_keymap "n") do
    local lhs = vim.api.nvim_replace_termcodes(binding.lhs, true, true, true)
    if lhs:sub(1, #prefix) == prefix and #lhs > #prefix then
      local suffix = vim.fn.keytrans(lhs:sub(#prefix + 1))
      -- Keep h for expanding/collapsing Git Status tree nodes.
      if suffix ~= "h" then
        map("n", suffix, binding.callback or binding.rhs, {
          buffer = state.bufnr,
          desc = binding.desc,
          silent = binding.silent == 1,
          expr = binding.expr == 1,
          remap = binding.noremap == 0,
          nowait = binding.nowait == 1,
        })
      end
    end
  end
end

return M
