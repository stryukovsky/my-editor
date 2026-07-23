local opt = vim.opt
local o = vim.o
local g = vim.g
-------------------------------------- options ------------------------------------------
o.laststatus = 3
o.showmode = false
vim.opt.title = true
vim.opt.titlestring = [[nvim | %{fnamemodify(getcwd(), ":~")}]]
vim.opt.foldcolumn = "1"
o.clipboard = "unnamedplus"
local handle = io.popen "which gpaste-client 2>/dev/null"
if handle ~= nil then
  local result = handle:read "*a"
  handle:close()
  if result ~= "" then
    vim.g.clipboard = {
      name = "gpaste",
      copy = {
        ["+"] = { "gpaste-client" },
        ["*"] = { "gpaste-client" },
      },
      paste = {
        ["+"] = { "gpaste-client", "--use-index", "get", "0" },
        ["*"] = { "gpaste-client", "--use-index", "get", "0" },
      },
    }
  end
end
o.cursorline = true
o.cursorlineopt = "number"
o.winborder = "rounded"
-- Indenting
o.expandtab = true
o.shiftwidth = 4
opt.tabstop = 1
o.smartindent = true
o.softtabstop = 1

g.matchparen_disable_cursor_hl = 1
g.enabled_virtual_lines = true
o.ignorecase = true
o.smartcase = true
o.mouse = "a"
-- Numbers
o.number = true
o.numberwidth = 2
o.ruler = true

-- Get all .add files from the spell directory
local config_dir = vim.fn.stdpath "config"
--
local spell_dir = vim.fn.expand(config_dir .. "/spell")
-- local spell_files = vim.fn.glob(spell_dir .. '/*', false, true)
local spell_files = vim.fn.glob(spell_dir .. "/*.add", false, true)

if #spell_files > 0 then
  vim.opt.spellfile = spell_files
end

-- disable nvim intro
opt.shortmess:append "sI"

vim.g.state_oil_opened = false

o.signcolumn = "yes"
o.splitbelow = true
o.splitright = true
o.timeoutlen = 400
o.undofile = true
o.swapfile = false
-- interval for writing swap file to disk, also used by gitsigns
o.updatetime = 250

opt.foldlevel = 9900
-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
opt.whichwrap:append "<>[]hl"

o.winborder = "rounded"
-- disable some default providers
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.loaded_node_provider = 0
g.loaded_python_provider = 0
g.loaded_python3_provider = 0
-- add binaries installed by mason.nvim to path
local is_windows = vim.fn.has "win32" ~= 0
local sep = is_windows and "\\" or "/"
local delim = is_windows and ";" or ":"
vim.env.PATH = table.concat({ vim.fn.stdpath "data", "mason", "bin" }, sep) .. delim .. vim.env.PATH

-- add yours here!

o.cursorlineopt = "both" -- to enable cursorline!
o.spelllang = "programming,en,ru"

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
  callback = function()
    if vim.api.nvim_buf_line_count(0) > 10000 or vim.fn.getfsize(vim.api.nvim_buf_get_name(0)) > 10240 then
      return
    end
    o.spell = true
    vim.o.spelloptions = "camel,noplainbuffer"

    local groups = ft_string_groups[vim.bo.filetype]
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
  callback = function()
    if vim.api.nvim_buf_line_count(0) > 10000 or vim.fn.getfsize(vim.api.nvim_buf_get_name(0)) > 10240 then
      return
    end
    -- Wait until Neovim is idle and the Tree-sitter parser is actually ready
    vim.schedule(function()
      -- Ensure the buffer still exists before applying options
      if vim.api.nvim_buf_is_valid(0) then
        vim.opt_local.foldmethod = "expr"
        vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      end
    end)
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

opt.number = true
opt.relativenumber = true
g.barbar_auto_setup = false -- disable auto-setup

local function escape(str)
  -- You need to escape these characters to work correctly
  local escape_chars = [[;,."|\]]
  return vim.fn.escape(str, escape_chars)
end

-- Recommended to use lua template string
local en = [[`qwertyuiop[]asdfghjkl;'zxcvbnm]]
local ru = [[ёйцукенгшщзхъфывапролджэячсмить]]
local en_shift = [[~QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>]]
local ru_shift = [[ËЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ]]

vim.opt.langmap = vim.fn.join({
  -- | `to` should be first     | `from` should be second
  escape(ru_shift) .. ";" .. escape(en_shift),
  escape(ru) .. ";" .. escape(en),
}, ",")

vim.opt.fillchars = {
  diff = "╱",
  eob = " ",
  foldopen = "", -- Arrow down for open folds
  foldclose = "", -- Arrow right for closed folds
  foldsep = " ", -- Blank space for lines inside an open fold
}

vim.filetype.add {
  filename = {
    ["todo.todotxt"] = "todotxt",
    ["done.todotxt"] = "todotxt",
  },
}

vim.opt.diffopt = {
  "internal",
  "filler",
  "closeoff",
  "context:12",
  "algorithm:histogram",
  "linematch:200",
  "indent-heuristic",
}

-- i cannot set nowrap for buffer only for window, so for bufleave i need return wrap back
local wide_buffers_wrap_toggling = vim.api.nvim_create_augroup("wide_buffers_wrap", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
  group = wide_buffers_wrap_toggling,
  pattern = "*.md",
  callback = function()
    if vim.api.nvim_buf_line_count(0) > 10000 or vim.fn.getfsize(vim.api.nvim_buf_get_name(0)) > 10240 then
      return
    end
    local max_table_line = 0
    for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
      if select(2, line:gsub("|", "")) >= 2 then
        local len = vim.fn.strdisplaywidth(line)
        if len > max_table_line then
          max_table_line = len
        end
      end
    end
    if max_table_line > 0 and vim.o.columns < max_table_line then
      vim.opt_local.wrap = false
    end
  end,
})

vim.api.nvim_create_autocmd("BufLeave", {
  group = wide_buffers_wrap_toggling,
  pattern = "*.md",
  callback = function()
    vim.opt_local.wrap = true
  end,
})

vim.api.nvim_create_autocmd("BufLeave", {
  group = wide_buffers_wrap_toggling,
  pattern = "plantuml-preview*",
  callback = function()
    vim.opt_local.wrap = true
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  group = wide_buffers_wrap_toggling,
  pattern = "plantuml-preview*",
  callback = function()
    vim.opt_local.wrap = false
  end,
})
