local M = {}
local map = require "mappings.map"

function _G.NativeExtraComplete(findstart, base)
  if vim.b.terminal_command then
    return require("terminal_reimagined.command_inside_vim_editor.completion.native").complete(
      findstart,
      base
    )
  end
  if vim.b.input_completion and vim.bo.filetype == "gitcommit" then
    return require("moonshine.input.completion").complete(findstart, base)
  end
  return findstart == 1 and -3 or {}
end

local ranking = require "native_completion"
local midword = require "native_completion.midword"
local trigger = require "native_completion.trigger"

local function refresh()
  local floating = vim.api.nvim_win_get_config(0).relative ~= ""
  local disabled = vim.b.completion == false
    or vim.bo.filetype == "TelescopePrompt"
    or vim.bo.buftype == "prompt"
    or (
      vim.bo.buftype ~= ""
      and not vim.b.terminal_command
      and not vim.b.input_completion
    )
  local lsp_completion = not vim.b.terminal_command
    and #vim.lsp.get_clients { bufnr = 0, method = "textDocument/completion" }
      > 0
  vim.opt_local.autocomplete = not disabled and not lsp_completion
  local input_source = vim.b.input_completion and vim.bo.filetype == "gitcommit"
  vim.opt_local.complete = input_source and { "F" }
    or vim.b.terminal_command and { "F", ".", "w", "b" }
    or { ".", "w", "b" }
  vim.opt_local.completeopt = floating
      and { "menu", "menuone", "noselect", "fuzzy", "nosort" }
    or { "menu", "menuone", "noselect", "fuzzy", "nosort", "popup" }
end

function M.refresh_completions()
  local buf = vim.api.nvim_get_current_buf()
  local clients =
    vim.lsp.get_clients { bufnr = buf, method = "textDocument/completion" }
  for _, client in ipairs(clients) do
    vim.lsp.completion.enable(false, client.id, buf)
  end
  if vim.b.completion ~= false then
    for _, client in ipairs(clients) do
      vim.lsp.completion.enable(true, client.id, buf, {
        autotrigger = false, -- Debounced by native_completion.trigger.
        cmp = ranking.compare,
        convert = ranking.convert,
      })
    end
  end
  refresh()
end

local group = vim.api.nvim_create_augroup("NativeCompletion", { clear = true })
vim.api.nvim_create_autocmd("CompleteChanged", {
  group = group,
  callback = midword.prepare,
})
vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "InsertLeave" }, {
  group = group,
  callback = function()
    midword.clear()
    trigger.clear()
  end,
})
-- Register before LSP enables its buffer-local native acceptance handler.
vim.api.nvim_create_autocmd("CompleteDone", {
  group = group,
  callback = midword.finish,
})
vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP" }, {
  group = group,
  callback = trigger.schedule,
})
vim.api.nvim_create_autocmd(
  { "BufEnter", "FileType", "LspAttach", "LspDetach" },
  {
    group = group,
    callback = function()
      ranking.invalidate()
      trigger.clear()
    end,
  }
)
vim.api.nvim_create_autocmd({ "CompleteChanged", "WinNew" }, {
  group = group,
  callback = function()
    vim.schedule(function()
      -- The default also copies every candidate and its LSP payload on each
      -- menu update. Only the preview handle is needed here.
      local win = vim.fn.complete_info({ "preview_winid" }).preview_winid
      if win and win > 0 and vim.api.nvim_win_is_valid(win) then
        vim.wo[win].winhighlight =
          "Normal:PmenuPreview,NormalFloat:PmenuPreview,FloatBorder:PmenuPreviewBorder"
        local border = vim.api.nvim_win_get_config(win).border
        if not border or border[1] ~= "╭" then
          vim.api.nvim_win_set_config(win, { border = "rounded" })
        end
      end
    end)
  end,
})
vim.api.nvim_create_autocmd(
  { "BufEnter", "WinEnter", "InsertEnter", "FileType" },
  { group = group, callback = refresh }
)
vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/completion", ev.buf) then
      M.refresh_completions()
      vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
      refresh()
    end
  end,
})
vim.api.nvim_create_autocmd("LspDetach", {
  group = group,
  callback = function()
    vim.schedule(refresh)
  end,
})
vim.api.nvim_create_autocmd("CompleteDone", {
  group = group,
  callback = function()
    local item = vim.v.completed_item
    local data = type(item.user_data) == "table" and item.user_data or {}
    if data.native_shell_start then
      local buf = vim.api.nvim_get_current_buf()
      local cursor = vim.api.nvim_win_get_cursor(0)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        local row, col = cursor[1] - 1, cursor[2]
        local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
          or ""
        if
          line:sub(1, data.native_shell_start) == data.native_shell_prefix
          and col >= data.native_shell_start
        then
          local tail = data.native_shell_quote
              and line:sub(col + 1, col + 1) == data.native_shell_quote
              and 1
            or 0
          vim.api.nvim_buf_set_text(
            buf,
            row,
            data.native_shell_start,
            row,
            col + tail,
            { data.native_shell_word or item.word }
          )
        end
      end)
    end
  end,
})
refresh()

-- Called after global LSP mappings so Ctrl-K can retain signature help as fallback.
function M.setup_mappings()
  local opts = { expr = true, silent = true, desc = "Completion" }
  map("i", "<C-Space>", function()
    if
      not vim.b.terminal_command
      and #vim.lsp.get_clients { bufnr = 0, method = "textDocument/completion" }
        > 0
    then
      vim.schedule(trigger.request)
      return ""
    end
    return "<C-n>"
  end, { expr = true, desc = "Show native completion" })
  map("i", "<C-x><C-n>", function()
    if
      vim.b.completion == false
      or vim.bo.buftype ~= ""
      or vim.b.terminal_command
    then
      return "<C-x><C-n>"
    end
    return (vim.fn.pumvisible() == 1 and "<C-e>" or "") .. "<C-n>"
  end, { expr = true, silent = true, desc = "Complete buffer words" })
  map("i", "<CR>", function()
    if vim.fn.pumvisible() == 0 then
      return "<CR>"
    end
    return vim.fn.complete_info({ "selected" }).selected >= 0 and "<C-y>"
      or "<C-e><CR>"
  end, {
    expr = true,
    silent = true,
    desc = "Accept selected completion or insert newline",
  })
  for _, key in ipairs { "<C-CR>", "<S-CR>", "<A-CR>" } do
    map("i", key, function()
      if vim.fn.pumvisible() == 0 then
        return ""
      end
      local selected = vim.fn.complete_info({ "selected" }).selected
      return selected < 0 and "<C-n><C-y>" or "<C-y>"
    end, {
      expr = true,
      silent = true,
      desc = "Accept selected or first completion",
    })
  end
  for key, direction in pairs {
    ["<C-j>"] = "<C-n>",
    ["<Down>"] = "<C-n>",
    ["<Up>"] = "<C-p>",
  } do
    map("i", key, function()
      return vim.fn.pumvisible() == 1 and direction or key
    end, opts)
  end
  map("i", "<C-k>", function()
    if vim.fn.pumvisible() == 1 then
      return "<C-p>"
    end
    vim.schedule(vim.lsp.buf.signature_help)
    return ""
  end, opts)
  map("c", "<C-Space>", "<Tab>", { desc = "Command-line completion" })
  for key, direction in pairs { ["<C-j>"] = "<C-n>", ["<C-k>"] = "<C-p>" } do
    map("c", key, function()
      return vim.fn.wildmenumode() == 1 and direction or key
    end, opts)
  end
end
return M
