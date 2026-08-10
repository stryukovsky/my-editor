-- Disable heavy features for large buffers.
-- Flag: vim.b.skip_heavy_operations (set on open; toggle with M.toggle / <leader>big).

local big_file_group = vim.api.nvim_create_augroup("BigFilePerformance", { clear = true })
local notify = require "configs.notify"

local M = {}

local max_filesize = 100 * 1024
local max_lines = 10000

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
  if vim.b[buf].large_file == true then
    return true
  end
  return vim.api.nvim_buf_line_count(buf) > max_lines
end

---Ensure skip_heavy_operations is set from size/line heuristic when still unset.
---@param buf integer
---@return boolean
local function ensure_flag(buf)
  if vim.b[buf].skip_heavy_operations == nil then
    vim.b[buf].skip_heavy_operations = heuristic_skip(buf)
  end
  return vim.b[buf].skip_heavy_operations == true
end

---@param buf integer
local function notify_if_needed(buf)
  if not vim.b[buf].skip_heavy_operations or vim.b[buf].large_file_notified then
    return
  end
  vim.b[buf].large_file_notified = true
  local name = vim.api.nvim_buf_get_name(buf)
  local label = name ~= "" and vim.fn.fnamemodify(name, ":t") or ("buffer " .. buf)
  notify.replace("bigfiles.auto", "Big file", "Heavy features disabled for " .. label, vim.log.levels.WARN)
end

---Return true if the buffer should skip heavy features.
---@param buf? integer buffer id; defaults to current buffer
local function skip(buf)
  buf = resolve_buf(buf)
  local should = ensure_flag(buf)
  if should then
    notify_if_needed(buf)
  end
  return should
end

---@param buf integer
local function detach_lsp(buf)
  for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
    pcall(vim.lsp.buf_detach_client, buf, client.id)
  end
end

---Apply light-mode settings (heavy features off). Keeps filetype unless already cleared on read.
---@param buf integer
---@param opts? { clear_filetype?: boolean, disable_swap_undo?: boolean }
local function apply_skipping_heavy_operations(buf, opts)
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
end

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

---Re-enable heavy features for a buffer.
---@param buf integer
local function apply_enabling_heavy_operations(buf)
  vim.bo[buf].swapfile = true
  vim.bo[buf].undofile = true

  vim.api.nvim_buf_call(buf, function()
    if vim.bo.filetype == "" then
      vim.cmd "filetype detect"
    end
    local ft = vim.bo.filetype
    if ft ~= "" then
      vim.bo.syntax = ft
    else
      vim.bo.syntax = ""
    end

    pcall(vim.treesitter.start, buf)
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.opt_local.spell = true
    vim.opt_local.spelloptions = "camel,noplainbuffer"
  end)

  vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  apply_hex_syntax(buf)

  vim.api.nvim_buf_call(buf, function()
        -- vim.lsp.start()
    -- pcall(vim.cmd, "LspStart")
  end)
end

---Toggle heavy features for the current (or given) buffer.
---@param buf? integer
function M.toggle(buf)
  buf = resolve_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  ensure_flag(buf)
  local skip_now = not vim.b[buf].skip_heavy_operations
  vim.b[buf].skip_heavy_operations = skip_now

  if skip_now then
    apply_skipping_heavy_operations(buf, { disable_swap_undo = true })
    notify.replace("bigfiles.toggle", "Big file", "Heavy features disabled for this buffer", vim.log.levels.INFO)
  else
    apply_enabling_heavy_operations(buf)
    notify.replace("bigfiles.toggle", "Big file", "Heavy features enabled for this buffer", vim.log.levels.INFO)
  end
end

vim.api.nvim_create_autocmd({ "BufReadPre", "FileReadPre" }, {
  group = big_file_group,
  pattern = "*",
  callback = function(args)
    local filepath = args.match
    local ok, stats = pcall(vim.uv.fs_stat, filepath)

    if ok and stats and stats.size > max_filesize then
      vim.b[args.buf].large_file = true
      vim.b[args.buf].skip_heavy_operations = true
      -- Buffer-local only — never global `:syntax off`.
      apply_skipping_heavy_operations(args.buf, { clear_filetype = true, disable_swap_undo = true })
    end
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = big_file_group,
  pattern = "*",
  callback = function(args)
    local buf = args.buf
    if vim.b[buf].skip_heavy_operations == nil then
      vim.b[buf].skip_heavy_operations = heuristic_skip(buf)
    end
    if vim.b[buf].skip_heavy_operations then
      notify_if_needed(buf)
      -- Size path already applied light settings; line-count path still needs them.
      if not vim.b[buf].large_file then
        apply_skipping_heavy_operations(buf)
      else
        pcall(vim.treesitter.stop, buf)
      end
    end
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = big_file_group,
  callback = function(args)
    if skip(args.buf) then
      return
    end

    vim.api.nvim_buf_call(args.buf, function()
      vim.opt_local.spell = true
      vim.opt_local.spelloptions = "camel,noplainbuffer"
    end)
    apply_hex_syntax(args.buf)
  end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  group = big_file_group,
  callback = function(args)
    if skip(args.buf) then
      return
    end

    -- nvim-treesitter main does not auto-enable highlighting.
    pcall(vim.treesitter.start, args.buf)

    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(args.buf) then
        return
      end
      if vim.b[args.buf].skip_heavy_operations then
        return
      end
      vim.api.nvim_buf_call(args.buf, function()
        vim.opt_local.foldmethod = "expr"
        vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      end)
    end)
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

local big_file_lsp_group = vim.api.nvim_create_augroup("BigFileLsp", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = big_file_lsp_group,
  callback = function(args)
    if skip(args.buf) then
      vim.lsp.buf_detach_client(args.buf, args.data.client_id)
    end
  end,
})

return M
