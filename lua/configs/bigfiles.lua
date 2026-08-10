local big_file_group = vim.api.nvim_create_augroup("BigFilePerformance", { clear = true })
local notify = require "configs.notify"

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
local function too_big_file(buf)
  return vim.b[buf].large_file == true
end

---@param buf integer
local function too_many_lines(buf)
  return vim.api.nvim_buf_line_count(buf) > max_lines
end

---Return true if the buffer should skip heavy features.
---@param buf? integer buffer id; defaults to current buffer
local function skip(buf)
  buf = resolve_buf(buf)
  local is_large = too_big_file(buf) or too_many_lines(buf)
  if is_large and not vim.b[buf].large_file_notified then
    vim.b[buf].large_file_notified = true
    local name = vim.api.nvim_buf_get_name(buf)
    local label = name ~= "" and vim.fn.fnamemodify(name, ":t") or ("buffer " .. buf)
    notify.send(
      "Big file",
      "Some features disabled for " .. label .. " because it is large",
      vim.log.levels.WARN
    )
  end
  return is_large
end

vim.api.nvim_create_autocmd({ "BufReadPre", "FileReadPre" }, {
  group = big_file_group,
  pattern = "*",
  callback = function(args)
    local filepath = args.match
    local ok, stats = pcall(vim.uv.fs_stat, filepath)

    if ok and stats and stats.size > max_filesize then
      -- Объявляем глобальную/буферную переменную, чтобы другие плагины знали о лимите
      vim.b[args.buf].large_file = true

      -- Buffer-local only — never `:syntax off` (that kills highlighting for the whole session).
      vim.bo[args.buf].syntax = "OFF"
      vim.bo[args.buf].swapfile = false
      vim.bo[args.buf].undofile = false
      vim.bo[args.buf].filetype = "" -- Отключает автокоманды типов файлов
      vim.api.nvim_buf_call(args.buf, function()
        vim.opt_local.foldmethod = "manual"
        vim.opt_local.spell = false
      end)
    end
  end,
})

-- Дополнительно принудительно останавливаем Tree-sitter при загрузке буфера
vim.api.nvim_create_autocmd("BufReadPost", {
  group = big_file_group,
  pattern = "*",
  callback = function(args)
    if vim.b[args.buf].large_file then
      pcall(vim.treesitter.stop, args.buf)
    end
  end,
})

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

vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function(args)
    if skip(args.buf) then
      return
    end

    vim.o.spell = true
    vim.o.spelloptions = "camel,noplainbuffer"

    local groups = ft_string_groups[vim.bo[args.buf].filetype]
    if not groups then
      return
    end

    local containedin = table.concat(groups, ",")

    vim.cmd(string.format(
      [[
      syntax match LuaHexPrefix /0x\x\+/ contains=@NoSpell containedin=%s extend
      syntax match LuaHexNoPrefix /\v[0-9A-Fa-f]{10,}/ contains=@NoSpell containedin=%s extend
      highlight default link LuaHexPrefix Number
      highlight default link LuaHexNoPrefix Number
    ]],
      containedin,
      containedin,
      containedin
    ))
  end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  callback = function(args)
    if skip(args.buf) then
      return
    end

    -- nvim-treesitter main does not auto-enable highlighting.
    pcall(vim.treesitter.start, args.buf)

    -- Wait until Neovim is idle and the Tree-sitter parser is actually ready
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(args.buf) then
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
