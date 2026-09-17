local keymaps = {
  replace = { n = "<C-r>", i = "<C-r>" },
  applyNext = { n = ";" },
  applyPrev = { n = "<A-;>" },
  abort = { n = "<C-c>", i = "<C-c>" },
  qflist = { n = "<C-q>", i = "<C-q>" },
  nextInput = { n = "<tab>", i = "<tab>" },
  prevInput = { n = "<s-tab>", i = "<s-tab>" },
  help = { n = "?" },
  close = { n = "q" },
  historyOpen = { n = "<leader>rt" },
  historyAdd = { n = "<leader>ra" },
  refresh = { n = "<leader>rf" },
  openLocation = { n = "<leader>ro" },
  openNextLocation = { n = "<down>" },
  openPrevLocation = { n = "<up>" },
  gotoLocation = { n = "<enter>" },
  pickHistoryEntry = { n = "<enter>" },
  toggleShowCommand = { n = "<leader>rw" },
  swapEngine = { n = "<leader>re" },
  previewLocation = { n = "<leader>ri" },
  swapReplacementInterpreter = { n = "<leader>rx" },
  syncNext = { n = "<leader>rc" },
  syncPrev = { n = "<leader>rp" },
  syncFile = { n = "<leader>rv" },
}

local header_actions = {
  { label = "Replace", key = "replace" },
  { label = "Apply Next", key = "applyNext" },
  { label = "Apply Prev", key = "applyPrev" },
  { label = "Input Next", key = "nextInput" },
  { label = "Input Prev", key = "prevInput" },
  { label = "Goto", key = "gotoLocation" },
  { label = "Abort", key = "abort" },
  { label = "Close", key = "close" },
  { label = "Qflist", key = "qflist" },
  { label = "Help", key = "help" },
}

---@param def grug.far.KeymapTable|string|boolean|nil
---@return string|nil
local function keymap_lhs(def)
  if type(def) == "string" then
    return def
  end
  if type(def) == "table" then
    return def.n or def.i
  end
end

local function mapping_header()
  local parts = {}
  for _, action in ipairs(header_actions) do
    local lhs = keymap_lhs(keymaps[action.key])
    if lhs then
      lhs = lhs:gsub("%%", "%%%%")
      parts[#parts + 1] = action.label .. " " .. lhs
    end
  end
  return "%#WinBar# " .. table.concat(parts, "   ")
end

local function set_mapping_header(buf)
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    return
  end
  vim.wo[win].winbar = mapping_header()
end

-- Plugin hooks only cover on_before_edit_file. FileType fires when the split is bound.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "grug-far",
  callback = function(ev)
    set_mapping_header(ev.buf)
    vim.api.nvim_create_autocmd("BufWinEnter", {
      buffer = ev.buf,
      callback = function()
        set_mapping_header(ev.buf)
      end,
    })
  end,
})

require("grug-far").setup {
  -- Open search and replace in a bottom split.
  windowCreationCommand = "botright split",
  startInInsertMode = true,
  transient = true,
  wrap = true,

  openTargetWindow = {
    exclude = require "utils.technical_ui_filetypes",
    preferredLocation = "prev",
    useScratchBuffer = false,
  },
  helpLine = { enabled = false },

  -- No maplocalleader in this config; use leader for buffer actions.
  keymaps = keymaps,

  engines = {
    astgrep = {
      -- Prefer the real binary name; bare `sg` is often shadow-utils on Linux.
      path = "ast-grep",
    },
  },
}
