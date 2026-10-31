local M = {}
local map = require "mappings.map"

-- LSP drives its own asynchronous completion; other buffers use native sources.
vim.o.autocomplete = true
vim.o.autocompletedelay = 100
vim.o.pumborder = "rounded"
vim.o.pumblend = 0
vim.opt.completeopt =
  { "menu", "menuone", "noselect", "fuzzy", "nosort", "popup" }
vim.opt.complete = { ".", "w", "b" }
vim.o.completefunc = "v:lua.NativeExtraComplete"
vim.opt.wildoptions = { "pum", "fuzzy" }
vim.opt.wildmode = { "longest:full", "full" }

function _G.NativeExtraComplete(findstart, base)
  if vim.b.terminal_command then
    return require("terminal_command.native").complete(findstart, base)
  end
  return findstart == 1 and -3 or {}
end

local kinds = vim.lsp.protocol.CompletionItemKind
local kind_priority = {}
for rank, group in ipairs {
  {
    kinds.Variable,
    kinds.Field,
    kinds.Property,
    kinds.Constant,
    kinds.EnumMember,
  },
  {
    kinds.Class,
    kinds.Interface,
    kinds.Struct,
    kinds.Enum,
    kinds.TypeParameter,
    kinds.Module,
  },
  { kinds.Function, kinds.Method, kinds.Constructor },
} do
  for _, kind in ipairs(group) do
    kind_priority[kind] = rank
  end
end
kind_priority[kinds.Snippet] = 99

local function compare(a, b)
  local item_a = vim.tbl_get(a, "user_data", "nvim", "lsp", "completion_item")
    or {}
  local item_b = vim.tbl_get(b, "user_data", "nvim", "lsp", "completion_item")
    or {}
  local rank_a, rank_b =
    kind_priority[item_a.kind] or 4, kind_priority[item_b.kind] or 4
  if rank_a ~= rank_b then
    return rank_a < rank_b
  end
  return (item_a.sortText or item_a.label or a.word)
    < (item_b.sortText or item_b.label or b.word)
end

local function refresh()
  local floating = vim.api.nvim_win_get_config(0).relative ~= ""
  local disabled = vim.b.completion == false
    or vim.bo.buftype == "prompt"
    or (vim.bo.buftype ~= "" and not vim.b.terminal_command)
  local lsp_completion = not vim.b.terminal_command
    and #vim.lsp.get_clients { bufnr = 0, method = "textDocument/completion" }
      > 0
  vim.opt_local.autocomplete = not disabled and not lsp_completion
  vim.opt_local.complete = vim.b.terminal_command and { "F", ".", "w", "b" }
    or { ".", "w", "b" }
  vim.opt_local.completeopt = floating
      and { "menu", "menuone", "noselect", "fuzzy", "nosort" }
    or { "menu", "menuone", "noselect", "fuzzy", "nosort", "popup" }
end

local group = vim.api.nvim_create_augroup("NativeCompletion", { clear = true })
vim.api.nvim_create_autocmd({ "CompleteChanged", "WinNew" }, {
  group = group,
  callback = function()
    vim.schedule(function()
      local win = vim.fn.complete_info().preview_winid
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
      -- Use the public LSP trigger path instead of re-entering completion via 'o'.
      local provider = client.server_capabilities.completionProvider
      if not vim.b[ev.buf].terminal_command then
        local triggers = provider.triggerCharacters or {}
        for char in
          ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"):gmatch "."
        do
          if not vim.tbl_contains(triggers, char) then
            triggers[#triggers + 1] = char
          end
        end
        provider.triggerCharacters = triggers
      end
      vim.lsp.completion.enable(true, client.id, ev.buf, {
        autotrigger = not vim.b[ev.buf].terminal_command,
        cmp = compare,
      })
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
      return "<C-x><C-o>"
    end
    return "<C-n>"
  end, { expr = true, desc = "Show native completion" })
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
  map(
    "i",
    "<C-CR>",
    function()
      if vim.fn.pumvisible() == 0 then
        return ""
      end
      local selected = vim.fn.complete_info({ "selected" }).selected
      return selected < 0 and "<C-n><C-y>" or "<C-y>"
    end,
    { expr = true, silent = true, desc = "Accept selected or first completion" }
  )
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
