local map = require "mappings.map"

local function open_selected_entry()
  local zipfile = vim.b.zipfile
  local entry = vim.api.nvim_get_current_line()
  if not zipfile or entry:sub(1, 1) == '"' or entry:sub(-1) == "/" then
    return
  end

  local uri = "zipfile://" .. zipfile .. "::" .. entry
  vim.cmd("noswapfile edit " .. vim.fn.fnameescape(uri))
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ZipViewerCurrentWindow", { clear = true }),
  pattern = "zip",
  callback = function(event)
    -- zip.vim installs its default <CR> mapping after assigning this filetype.
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(event.buf) and vim.bo[event.buf].filetype == "zip" then
        map("n", "<CR>", open_selected_entry, { buffer = event.buf, silent = true, desc = "ZIP open entry in current window" })
      end
    end)
  end,
})
