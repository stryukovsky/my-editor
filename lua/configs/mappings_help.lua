-- Curated cheatsheet for lua/mappings. Grouping is intentional, not an auto-scan.
local map = require "mappings.map"

local M = {}

---@type { title: string, items: { string, string }[] }[]
local SECTIONS = {
  {
    title = "Actions",
    items = {
      { "<leader>ca", "LSP code action" },
      { "<leader>sa", "spelling suggestions" },
      { "<leader>ta", "convert text case" },
      { "<leader>aa", "AI actions" },
    },
  },
  {
    title = "Modes",
    items = {
      { "<A-G>", "grammar-strict spell" },
      { "<A-v>", "diagnostic virtual lines" },
      { "<A-h>", "git hunk overlay" },
      { "<A-W>", "wrap (also <A-r>)" },
      { "<A-1>", "relative line numbers" },
      { "<A-Z>", "zen UI" },
      { "<leader>zen", "zen mode" },
    },
  },
  {
    title = "Views",
    items = {
      { "<A-e>", "files tree" },
      { "<A-l>", "document symbols" },
      { "<A-o>", "oil file browser" },
      { "<leader><leader>", "find files" },
      { "<A-b>", "buffers tree" },
      { "<A-P>", "projects" },
      { "<A-z>", "oldfiles" },
      { "<A-f>", "find in current buffer" },
      { "<A-F>", "live grep" },
      { "<A-c>", "git commits" },
      { "<A-g>", "git branches" },
      { "<A-k>", "git status" },
      { "<A-m>", "marks (grapple)" },
      { "<A-u>", "undo tree" },
      { "<A-j>", "TODOs" },
      { "<A-R>", "find and replace" },
      { "<A-p>", "trouble diagnostics" },
      { "<A-i>", "trouble LSP / diagnostic float" },
      { "<A-t>", "test summary" },
      { "<A-T>", "test output" },
      { "<leader>th", "colorscheme" },
      { "<leader>notify", "notification history" },
    },
  },

  {
    title = "Navigation",
    items = {
      { "]g", "next git hunk" },
      { "[g", "prev git hunk" },
      { "]d", "next diagnostic" },
      { "[d", "prev diagnostic" },
      { "<A-,>", "prev buffer" },
      { "<A-.>", "next buffer" },
      { "<A-<>", "prev tab" },
      { "<A-S-.>", "next tab" },
      { "<A-[>", "tag stack pop" },
      { "<A-]>", "tag stack next" },
      { "<A-a>", "window left" },
      { "<A-s>", "window down" },
      { "<A-w>", "window up" },
      { "<A-d>", "window right" },
      { "+", "window wider" },
      { "_", "window narrower" },
      { "f", "flash jump" },
      { "F", "flash treesitter" },
      { "H", "LSP hover" },
      { "K", "LSP signature" },
      { "<leader>x", "close buffer" },
      { "<leader>X", "close other buffers" },
      { "<A-space>", "pick buffer" },
    },
  },
  {
    title = "Macros",
    items = {
      { "<leader>q", "start / stop recording" },
      { "Q", "play macro" },
      { "<C-q>", "switch macro slot" },
      { "cq", "edit macro" },
      { "dq", "delete all macros" },
      { "yq", "yank macro" },
      { "q", "disabled (nop)" },
    },
  },
  {
    title = "Git",
    items = {
      { "<leader>gg", "status (also <A-k>)" },
      { "<leader>gc", "commit" },
      { "<leader>gpush", "push" },
      { "<leader>gpull", "pull" },
      { "<leader>gfetch", "fetch" },
      { "<leader>gmerge", "merge" },
      { "<leader>gd", "diff" },
      { "<leader>gb", "branch" },
      { "<leader>gl", "log current branch" },
      { "<leader>gL", "log other branch" },
      { "<leader>gC", "review source into target" },
      { "<leader>gH", "review branch history" },
      { "<leader>gh", "view hunk" },
      { "<leader>gv", "select hunk" },
      { "<leader>gr", "reset hunk" },
      { "<leader>gR", "reset buffer" },
      { "<leader>gS", "stage all" },
      { "<leader>gx", "conflicts" },
    },
  },
  {
    title = "Search",
    items = {
      { "/", "search forward" },
      { "<A-q>", "search forward" },
      { "<A-Q>", "search backward" },
      { "v ?", "search back in selection" },
      { "n", "next match" },
      { "N", "previous match" },
      { "*", "word forward" },
      { "<leader>fw", "word in current buffer" },
    },
  },
  {
    title = "LSP",
    items = {
      { "<leader>lr", "find references" },
      { "<leader>ld", "find definition" },
      { "<leader>ltd", "find type definition" },
      { "<leader>fm", "format file" },
      { "<leader>rn", "rename symbol" },
      { "<leader>lsp", "LSP picker" },
      { "<leader>li", "LSP implementations" },
      { "<leader>lci", "incoming calls" },
      { "<leader>lco", "outgoing calls" },
    },
  },
  {
    title = "Treesj",
    items = {
      { "<leader>ss", "split" },
      { "<leader>sj", "join" },
    },
  },
  {
    title = "Refactor",
    items = {

      { "<leader>Re", "extract function" },
      { "<leader>Rf", "extract function to file" },
      { "<leader>Rv", "extract variable" },
      { "<leader>Ri", "inline variable" },
      { "<leader>RI", "inline function" },
    },
  },
}

---@type integer|nil
local help_win

function M.close()
  local win = help_win
  help_win = nil
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

local COLS = 3
local COL_GAP = 4

local function pad_to(s, width)
  local w = vim.fn.strdisplaywidth(s)
  if w < width then
    return s .. string.rep(" ", width - w)
  end
  return s
end

---@param section { title: string, items: { string, string }[] }
local function render_section(section)
  local key_width = 0
  for _, item in ipairs(section.items) do
    key_width = math.max(key_width, vim.fn.strdisplaywidth(item[1]))
  end

  ---@type string[]
  local lines = { " " .. section.title, "" }
  ---@type { line: integer, col: integer, end_col: integer, hl: string }[]
  local highlights = {
    { line = 0, col = 1, end_col = 1 + #section.title, hl = "Title" },
  }

  for _, item in ipairs(section.items) do
    local pad = string.rep(" ", key_width - vim.fn.strdisplaywidth(item[1]))
    lines[#lines + 1] = string.format("  %s%s  %s", item[1], pad, item[2])
    highlights[#highlights + 1] = {
      line = #lines - 1,
      col = 2,
      end_col = 2 + #item[1],
      hl = "TelescopeResultsIdentifier",
    }
  end

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end

  return { lines = lines, highlights = highlights, width = width + 1 }
end

function M.toggle()
  if vim.bo.filetype:match "^Telescope" then
    return
  end
  if help_win and vim.api.nvim_win_is_valid(help_win) then
    M.close()
    return
  end

  local rendered = {}
  for _, section in ipairs(SECTIONS) do
    rendered[#rendered + 1] = render_section(section)
  end

  ---@type { lines: string[], highlights: table[], width: integer }[][]
  local grid = {}
  for i = 1, #rendered, COLS do
    local row = {}
    for j = i, math.min(i + COLS - 1, #rendered) do
      row[#row + 1] = rendered[j]
    end
    grid[#grid + 1] = row
  end

  local max_row_width = 0
  for _, row in ipairs(grid) do
    local w = 0
    for c, col in ipairs(row) do
      w = w + col.width
      if c > 1 then
        w = w + COL_GAP
      end
    end
    max_row_width = math.max(max_row_width, w)
  end

  local width = math.min(vim.o.columns - 2, math.max(max_row_width + 2, math.floor(vim.o.columns * 0.92)))
  local inner = width - 2
  for _, row in ipairs(grid) do
    local used = COL_GAP * math.max(#row - 1, 0)
    for _, col in ipairs(row) do
      used = used + col.width
    end
    local extra = inner - used
    if extra > 0 and #row > 0 then
      local add = math.floor(extra / #row)
      local rem = extra - add * #row
      for c, col in ipairs(row) do
        col.width = col.width + add + (c == #row and rem or 0)
      end
    end
  end

  ---@type string[]
  local lines = {}
  ---@type { line: integer, col: integer, end_col: integer, hl: string }[]
  local highlights = {}

  for r, row in ipairs(grid) do
    if r > 1 then
      lines[#lines + 1] = ""
    end
    local height = 0
    for _, col in ipairs(row) do
      height = math.max(height, #col.lines)
    end
    local base = #lines
    for i = 1, height do
      local chunks = {}
      local byte = 0
      for c, col in ipairs(row) do
        if c > 1 then
          chunks[#chunks + 1] = string.rep(" ", COL_GAP)
          byte = byte + COL_GAP
        end
        local src = col.lines[i]
        chunks[#chunks + 1] = pad_to(src or "", col.width)
        if src then
          for _, h in ipairs(col.highlights) do
            if h.line == i - 1 then
              highlights[#highlights + 1] = {
                line = base + i - 1,
                col = byte + h.col,
                end_col = byte + h.end_col,
                hl = h.hl,
              }
            end
          end
        end
        byte = byte + col.width
      end
      lines[#lines + 1] = table.concat(chunks)
    end
  end

  lines[#lines + 1] = ""
  local footer = "  q  Esc  ?  <A-?>   close"
  lines[#lines + 1] = footer
  highlights[#highlights + 1] = { line = #lines - 1, col = 2, end_col = #footer, hl = "Comment" }

  local height = math.min(vim.o.lines - 3, math.max(#lines, math.floor(vim.o.lines * 0.88)))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "mappings-help"
  vim.bo[buf].modifiable = false
  vim.bo[buf].swapfile = false

  help_win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    style = "minimal",
    border = "rounded",
    title = " Mappings ",
    title_pos = "center",
    zindex = 200,
  })

  local win = help_win
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].statuscolumn = ""

  local ns = vim.api.nvim_create_namespace "mappings_help"
  for _, h in ipairs(highlights) do
    pcall(vim.hl.range, buf, ns, h.hl, { h.line, h.col }, { h.line, h.end_col })
  end

  local opts = { buffer = buf, silent = true, nowait = true, desc = "Close mappings help" }
  map("n", "q", M.close, opts)
  map("n", "<Esc>", M.close, opts)
  map("n", "?", M.close, opts)
  map("n", "<A-S-/>", M.close, opts)

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = M.close,
  })
end

return M
