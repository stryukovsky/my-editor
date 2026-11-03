local M = {}

-- Child processes edit in this instance rather than starting a nested Neovim.
local editor = vim.fn.shellescape(vim.fn.stdpath "config" .. "/bin/nvim-editor")
vim.env.EDITOR = editor
vim.env.VISUAL = editor
vim.env.GIT_EDITOR = editor
vim.env.GIT_SEQUENCE_EDITOR = editor
vim.env.NVIM_EDITOR_BIN = vim.v.progpath
vim.env.NVIM = vim.v.servername ~= "" and vim.v.servername or vim.fn.serverstart()

function M.open(paths)
  vim.cmd.stopinsert()
  local buffers = {}
  for _, path in ipairs(paths) do
    local buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)
    vim.bo[buf].buflisted = true
    buffers[#buffers + 1] = buf
  end
  -- :drop reuses a window showing the file, and preserves modified buffers.
  vim.cmd("drop " .. vim.fn.fnameescape(paths[1]))
  return buffers
end

function M.waiting(buffers)
  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(buf) then
      return true
    end
  end
  return false
end

return M
