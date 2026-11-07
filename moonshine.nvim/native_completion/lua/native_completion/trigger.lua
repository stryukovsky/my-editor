local M = {}
local api = vim.api
local timer
local generation = 0
local last_request

local function input()
  return {
    buf = api.nvim_get_current_buf(),
    win = api.nvim_get_current_win(),
    cursor = api.nvim_win_get_cursor(0),
    line = api.nvim_get_current_line(),
  }
end

function M.cancel()
  generation = generation + 1
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

function M.clear()
  M.cancel()
  last_request = nil
end

local function eligible()
  return vim.b.completion ~= false
    and not vim.b.terminal_command
    and (vim.bo.buftype == "" or vim.b.input_completion == true)
    and vim.bo.filetype ~= "TelescopePrompt"
    and vim.api.nvim_get_mode().mode:sub(1, 1) == "i"
end

function M.request()
  M.cancel()
  if not eligible() then
    return
  end
  local clients =
    vim.lsp.get_clients { bufnr = 0, method = "textDocument/completion" }
  if #clients == 0 then
    return
  end
  last_request = input()
  require("native_completion").prepare()
  -- Native completion sends asynchronous requests and applies results to the menu.
  -- Retain its snippet, resolve, text-edit, and incomplete-list handling.
  vim.lsp.completion.get()
end

function M.schedule()
  M.cancel()
  if not eligible() or vim.fn.complete_info({ "selected" }).selected >= 0 then
    return
  end
  -- complete() can itself cause TextChangedP. Incomplete server results must
  -- only be requested again after actual input, not after displaying the menu.
  if vim.deep_equal(last_request, input()) then
    return
  end
  if
    #vim.lsp.get_clients { bufnr = 0, method = "textDocument/completion" } == 0
  then
    return
  end
  local cursor = api.nvim_win_get_cursor(0)
  local before = api.nvim_get_current_line():sub(1, cursor[2])
  local char = vim.fn.strcharpart(before, vim.fn.strchars(before) - 1, 1)
  local trigger = vim.fn.matchstr(char, [[\k]]) ~= ""
  if not trigger then
    for _, client in
      ipairs(
        vim.lsp.get_clients { bufnr = 0, method = "textDocument/completion" }
      )
    do
      local provider = client.server_capabilities.completionProvider or {}
      trigger = trigger
        or vim.tbl_contains(provider.triggerCharacters or {}, char)
    end
  end
  if not trigger then
    return
  end
  local buf, win = api.nvim_get_current_buf(), api.nvim_get_current_win()
  local tick, token = api.nvim_buf_get_changedtick(buf), generation
  timer = vim.defer_fn(function()
    -- A stopped timer can already have queued its Lua callback.
    if token ~= generation then
      return
    end
    timer = nil
    if
      api.nvim_get_current_buf() ~= buf
      or api.nvim_get_current_win() ~= win
      or api.nvim_buf_get_changedtick(buf) ~= tick
      or not vim.deep_equal(api.nvim_win_get_cursor(win), cursor)
    then
      return
    end
    M.request()
  end, vim.o.autocompletedelay)
end

return M
