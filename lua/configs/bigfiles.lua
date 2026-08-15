-- Disable heavy features for large buffers.
-- Single flag: vim.b.skip_heavy_operations (init on open; toggle via M.toggle / <leader>big).

local big_file_group = vim.api.nvim_create_augroup("BigFilePerformance", { clear = true })
local big_file_lsp_group = vim.api.nvim_create_augroup("BigFileLsp", { clear = true })
local notify = require "configs.notify"

local M = {}

local max_filesize = 100 * 1024
local max_lines = 10000

local ft_string_groups = {
  json = { "jsonString" },
  javascript = { "jsString", "jsTemplateLiteral" },
  typescript = { "typescriptString", "typescriptTemplate" },
  go = { "goString" },
  rust = { "rustString" },
  scala = { "scalaString", "scalaMultilineString" },
  java = { "javaString" },
  kotlin = { "kotlinString" },
  sh = { "shString", "shDoubleQuote", "shSingleQuote" },
  bash = { "shString", "shDoubleQuote", "shSingleQuote" },
  python = { "pythonString", "pythonTripleQuotes" },
}

---@param buf? integer
---@return integer
local function resolve_buf(buf)
  if buf and buf ~= 0 then
    return buf
  end
  return vim.api.nvim_get_current_buf()
end

---@param buf integer
---@return boolean
local function heuristic_skip(buf)
  return vim.b[buf].large_file == true or vim.api.nvim_buf_line_count(buf) > max_lines
end

---Read skip flag; initialize from heuristic when unset.
---@param buf? integer
---@return boolean
local function is_skipping(buf)
  buf = resolve_buf(buf)
  if vim.b[buf].skip_heavy_operations == nil then
    vim.b[buf].skip_heavy_operations = heuristic_skip(buf)
  end
  return vim.b[buf].skip_heavy_operations == true
end

---@param buf? integer
---@param value boolean
local function set_skipping(buf, value)
  vim.b[resolve_buf(buf)].skip_heavy_operations = value and true or false
end

---@param buf integer
local function notify_auto_once(buf)
  if vim.b[buf].large_file_notified then
    return
  end
  vim.b[buf].large_file_notified = true
  local name = vim.api.nvim_buf_get_name(buf)
  local label = name ~= "" and vim.fn.fnamemodify(name, ":t") or ("buffer " .. buf)
  notify.replace("bigfiles.auto", "Big file", "Heavy features disabled for " .. label, vim.log.levels.WARN)
end

---@param buf integer
local function detach_lsp(buf)
  for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
    pcall(vim.lsp.buf_detach_client, buf, client.id)
  end
end

---@param buf integer
---@return boolean
local function skip_minidiff(buf)
  return vim.b[buf].minidiff_review == true or vim.b[buf].large_hunk_viewer == true
end

---@param buf integer
local function disable_minidiff(buf)
  if skip_minidiff(buf) then
    return
  end
  vim.b[buf].minidiff_disable = true
  pcall(require("mini.diff").disable, buf)
end

---@param buf integer
local function enable_minidiff(buf)
  if skip_minidiff(buf) then
    return
  end
  vim.b[buf].minidiff_disable = false
  pcall(require("mini.diff").enable, buf)
end

---@param buf integer
local function apply_hex_syntax(buf)
  local groups = ft_string_groups[vim.bo[buf].filetype]
  if not groups then
    return
  end
  local containedin = table.concat(groups, ",")
  vim.api.nvim_buf_call(buf, function()
    vim.cmd(string.format(
      [[
      syntax match LuaHexPrefix /0x\x\+/ contains=@NoSpell containedin=%s extend
      syntax match LuaHexNoPrefix /\v[0-9A-Fa-f]{10,}/ contains=@NoSpell containedin=%s extend
      highlight default link LuaHexPrefix Number
      highlight default link LuaHexNoPrefix Number
    ]],
      containedin,
      containedin
    ))
  end)
end

---@param buf integer
---@param opts? { clear_filetype?: boolean, disable_swap_undo?: boolean }
local function disable_heavy(buf, opts)
  opts = opts or {}
  pcall(vim.treesitter.stop, buf)
  vim.bo[buf].syntax = "OFF"
  vim.bo[buf].indentexpr = ""
  if opts.disable_swap_undo then
    vim.bo[buf].swapfile = false
    vim.bo[buf].undofile = false
  end
  if opts.clear_filetype then
    vim.bo[buf].filetype = ""
  end
  vim.api.nvim_buf_call(buf, function()
    vim.opt_local.foldmethod = "manual"
    vim.opt_local.spell = false
  end)
  detach_lsp(buf)
  disable_minidiff(buf)
end

---@param buf integer
local function enable_heavy(buf)
  vim.bo[buf].swapfile = true
  vim.bo[buf].undofile = true

  vim.api.nvim_buf_call(buf, function()
    if vim.bo.filetype == "" then
      vim.cmd "filetype detect"
    end
    local ft = vim.bo.filetype
    vim.bo.syntax = ft ~= "" and ft or ""

    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.opt_local.spell = true
    vim.opt_local.spelloptions = "camel,noplainbuffer"
  end)

  vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  apply_hex_syntax(buf)

  vim.api.nvim_buf_call(buf, function()
    pcall(vim.cmd, "LspStart")
  end)
  enable_minidiff(buf)
end

---@param buf? integer
function M.toggle(buf)
  buf = resolve_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local skip_now = not is_skipping(buf)
  set_skipping(buf, skip_now)

  if skip_now then
    disable_heavy(buf, { disable_swap_undo = true })
    notify.replace("bigfiles.toggle", "Big file", "Heavy features disabled for this buffer", vim.log.levels.INFO)
  else
    enable_heavy(buf)
    notify.replace("bigfiles.toggle", "Big file", "Heavy features enabled for this buffer", vim.log.levels.INFO)
  end
end

vim.api.nvim_create_autocmd({ "BufReadPre", "FileReadPre" }, {
  group = big_file_group,
  pattern = "*",
  callback = function(args)
    local ok, stats = pcall(vim.uv.fs_stat, args.match)
    if not (ok and stats and stats.size > max_filesize) then
      -- file is definitely small judging by filesize so do not set it as large
      -- cannot read lines count - if it is big by count of lines it will be applied later
      return
    end

    -- otherwise set it - stats says file is large and its enough to consider file as large
    vim.b[args.buf].large_file = true
    set_skipping(args.buf, true)
    -- Buffer-local only — never global `:syntax off`.
    disable_heavy(args.buf, { clear_filetype = true, disable_swap_undo = true })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = big_file_group,
  pattern = "*",
  callback = function(args)
    if is_skipping(args.buf) then
      notify_auto_once(args.buf)
      disable_heavy(args.buf)
    end
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = big_file_group,
  callback = function(args)
    if is_skipping(args.buf) then
      return
    end

    vim.api.nvim_buf_call(args.buf, function()
      vim.opt_local.spell = true
      vim.opt_local.spelloptions = "camel,noplainbuffer"
    end)
    apply_hex_syntax(args.buf)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = big_file_group,
  callback = function(args)
    if is_skipping(args.buf) then
      return
    end

    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(args.buf) or is_skipping(args.buf) then
        return
      end
      vim.api.nvim_buf_call(args.buf, function()
        vim.opt_local.foldmethod = "expr"
        vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      end)
    end)
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
  group = big_file_group,
  callback = function(args)
    if skip_minidiff(args.buf) then
      return
    end
    if is_skipping(args.buf) or vim.b[args.buf].large_file then
      disable_minidiff(args.buf)
    end
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = big_file_lsp_group,
  callback = function(args)
    if is_skipping(args.buf) then
      vim.lsp.buf_detach_client(args.buf, args.data.client_id)
    end
  end,
})

return M
