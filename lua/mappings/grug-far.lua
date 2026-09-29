local map = require "mappings.map"

local function result_at_cursor()
  local inst = require("grug-far").get_instance(0)
  if not inst then
    return nil
  end
  return require("grug-far.render.resultsList").getResultLocationAtCursor(inst._buf, inst._context)
end

local function goto_result()
  local loc = result_at_cursor()
  if not loc or not loc.filename then
    return
  end

  vim.cmd("edit " .. vim.fn.fnameescape(loc.filename))

  local lnum = loc.lnum or 1
  local line_count = vim.api.nvim_buf_line_count(0)
  if line_count < 1 then
    return
  end
  lnum = math.max(1, math.min(lnum, line_count))
  local text = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
  local col = loc.col and math.max(loc.col - 1, 0) or 0
  col = math.min(col, #text)
  vim.api.nvim_win_set_cursor(0, { lnum, col })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "grug-far",
  callback = function(ev)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(ev.buf) then
        return
      end
      map("n", "<CR>", goto_result, { buffer = ev.buf, desc = "grug-far edit result" })
    end)
  end,
})
