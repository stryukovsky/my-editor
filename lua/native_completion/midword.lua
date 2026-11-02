local M = {}
local api = vim.api
local pending

local function eligible()
  return vim.bo.buftype == ""
    and not vim.b.terminal_command
    and not vim.b.input_completion
    and vim.b.completion ~= false
end

-- Capture actual input, never the temporary text inserted while selecting items.
function M.prepare()
  if not eligible() or vim.fn.complete_info({ "selected" }).selected >= 0 then
    return
  end
  local cursor = api.nvim_win_get_cursor(0)
  pending = {
    buf = api.nvim_get_current_buf(),
    win = api.nvim_get_current_win(),
    row = cursor[1],
    col = cursor[2],
    line = api.nvim_get_current_line(),
  }
end

function M.clear()
  pending = nil
end

function M.finish()
  local original = pending
  pending = nil
  if
    not original
    or vim.v.event.reason ~= "accept"
    or not eligible()
    or original.buf ~= api.nvim_get_current_buf()
    or original.win ~= api.nvim_get_current_win()
  then
    return
  end
  local completed = vim.v.completed_item
  local lsp = vim.tbl_get(completed, "user_data", "nvim", "lsp")
  local item = lsp and lsp.completion_item
  local client = lsp and vim.lsp.get_client_by_id(lsp.client_id)
  if not item or not client then
    return
  end
  local cursor = api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]
  local word = completed.word or ""
  local start = col - #word
  local tail = original.line:sub(original.col + 1)
  if
    row ~= original.row
    or start < 0
    or start > original.col
    or tail == ""
    or api.nvim_get_current_line()
      ~= original.line:sub(1, start) .. word .. tail
  then
    return
  end

  local remove = 0
  if item.textEdit then
    -- Native completion uses the insert range for InsertReplaceEdit.
    local range = item.textEdit.range or item.textEdit.insert
    if
      not range
      or range.start.line ~= row - 1
      or range["end"].line ~= row - 1
    then
      return
    end
    local ok, finish = pcall(
      vim.str_byteindex,
      original.line,
      client.offset_encoding,
      range["end"].character,
      true
    )
    if not ok or finish < original.col or finish > #original.line then
      return
    end
    remove = finish - original.col
  elseif item.insertTextFormat ~= 2 then
    local prefix = original.line:sub(start + 1, original.col)
    -- Only infer overlap for plain identifiers and an exact typed prefix.
    if
      vim.fn.matchstr(word, [[^\k\+$]]) == word
      and vim.startswith(word, prefix)
    then
      local remainder = word:sub(#prefix + 1)
      if remainder ~= "" and vim.fn.matchstr(tail, [[^\k*]]) == remainder then
        remove = #remainder
      end
    end
  end
  if remove > 0 then
    -- Run before native CompleteDone expands snippets or applies other edits.
    -- Keep this deletion in the same undo block as the accepted word.
    vim.cmd "undojoin"
    api.nvim_buf_set_text(
      original.buf,
      row - 1,
      col,
      row - 1,
      col + remove,
      { "" }
    )
  end
end

return M
