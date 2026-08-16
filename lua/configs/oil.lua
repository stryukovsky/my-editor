local oil = require "oil"
local notify = require "configs.notify"
local system_file_explorer = require "utils.system_file_explorer"
local neotree_command = require "neo-tree.command"

local compact_columns = { "icon" }
local detail_columns = { "icon", "permissions", "size", "mtime" }
local detail = true

local skip_preview_ext = {
  mp3 = true,
  wav = true,
  flac = true,
  ogg = true,
  m4a = true,
  mp4 = true,
  mkv = true,
  webm = true,
  avi = true,
  zip = true,
  tar = true,
  gz = true,
  bz2 = true,
  xz = true,
  ["7z"] = true,
  rar = true,
  o = true,
  so = true,
  a = true,
  class = true,
  jar = true,
  wasm = true,
}

function _G.get_oil_winbar()
  local win = vim.g.statusline_winid
  local bufnr = vim.api.nvim_win_get_buf(win)
  local dir = oil.get_current_dir(bufnr)
  if dir then
    return " Current location: " .. vim.fn.fnamemodify(dir, ":~")
  end
  return " Current location: " .. vim.api.nvim_buf_get_name(bufnr)
end

local function search_here()
  require("searchbox").incsearch()
end

local M = {}

local explorer_filetypes = {
  oil = true,
  netrw = true,
}

local function is_restorable_buf(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  if explorer_filetypes[vim.bo[buf].filetype] then
    return false
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name ~= "" and vim.fn.isdirectory(name) == 1 then
    return false
  end
  return true
end

local function show_empty_in(win)
  require("configs.dashboard").open_in(win)
end

function M.visible()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "oil" then
      return true
    end
  end
  return false
end

function M.close()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and (vim.wo[win].previewwindow or vim.w[win].oil_preview) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "oil" then
        local orig = vim.w[win].oil_original_buffer
        if is_restorable_buf(orig) then
          vim.api.nvim_win_set_buf(win, orig)
          local view = vim.w[win].oil_original_view
          if view then
            vim.api.nvim_win_call(win, function()
              vim.fn.winrestview(view)
            end)
          end
        else
          show_empty_in(win)
        end
      end
    end
  end
  vim.g.state_oil_opened = false
end

function M.toggle()
  if M.visible() then
    M.close()
    _G.dialog_component_callback_close = function() end
    return
  end
  _G.dialog_component_callback_close()
  _G.dialog_component_callback_close = function()
    M.close()
    _G.dialog_component_callback_close = function() end
  end
  vim.cmd "Neotree close"
  oil.open(vim.fn.getcwd(), { preview = { vertical = true } })
  vim.g.state_oil_opened = true
end

local function close_oil()
  M.close()
end

local function open_under_cursor()
  local entry = oil.get_cursor_entry()
  if not entry then
    return
  end
  if require("oil.util").is_directory(entry) then
    oil.select()
    return
  end
  oil.select({ close = true }, function()
    M.close()
  end)
end

local function open_ghostty()
  local dir = oil.get_current_dir()
  if not dir then
    notify.send("Oil", "No local directory", vim.log.levels.WARN)
    return
  end
  vim.fn.jobstart({ "ghostty", "--working-directory=" .. dir }, { detach = true })
end

local function open_in_files()
  local entry = oil.get_cursor_entry()
  local dir = oil.get_current_dir()
  if not dir then
    return
  end
  local path = dir
  if entry and entry.name ~= ".." then
    path = dir .. entry.name
  end
  system_file_explorer(path)
end

local function set_nvim_root()
  local dir = oil.get_current_dir()
  if not dir then
    notify.send("Oil", "No local directory", vim.log.levels.WARN)
    return
  end
  local entry = oil.get_cursor_entry()
  local root = dir
  if entry then
    if entry.name == ".." then
      root = vim.fs.dirname((dir:gsub("/+$", "")))
    elseif require("oil.util").is_directory(entry) then
      root = dir .. entry.name
    end
  end
  root = vim.fs.normalize(root)
  vim.api.nvim_cmd({ cmd = "tcd", args = { root } }, {})
  oil.open(root)
  notify.send("Oil", "Root: " .. vim.fn.fnamemodify(root, ":~"), vim.log.levels.INFO)
end

local function yank_path()
  require("oil.actions").yank_entry.callback { modify = ":~" }
  local path = vim.fn.getreg(vim.v.register)
  if path ~= "" then
    vim.fn.setreg("+", path)
    notify.send("Oil", "Copied: " .. path, vim.log.levels.INFO)
  end
end

oil.setup {
  default_file_explorer = false,
  columns = detail_columns,
  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,
  constrain_cursor = "name",
  watch_for_changes = true,
  use_default_keymaps = false,
  buf_options = {
    buflisted = false,
    bufhidden = "hide",
  },
  win_options = {
    wrap = false,
    signcolumn = "no",
    cursorcolumn = false,
    foldcolumn = "0",
    spell = false,
    list = false,
    conceallevel = 3,
    concealcursor = "nvic",
    cursorline = true,
    number = false,
    relativenumber = false,
    winbar = "%!v:lua.get_oil_winbar()",
  },
  view_options = {
    show_hidden = true,
    natural_order = "fast",
    case_insensitive = true,
    sort = {
      { "type", "asc" },
      { "name", "asc" },
    },
  },
  preview_win = {
    update_on_cursor_moved = true,
    preview_method = "fast_scratch",
    disable_preview = function(filename)
      local size = vim.fn.getfsize(filename)
      if size < 0 or size > 2 * 1024 * 1024 then
        return true
      end
      local ext = filename:match "%.([^./]+)$"
      return ext ~= nil and skip_preview_ext[ext:lower()] == true
    end,
    win_options = {
      wrap = true,
      linebreak = true,
    },
  },
  keymaps = {
    ["g?"] = { "actions.show_help", mode = "n" },
    ["<CR>"] = { callback = open_under_cursor, desc = "Open", mode = "n" },
    ["<A-p>"] = "actions.preview",
    ["<A-e>"] = function(_) end,
    ["<A-l>"] = function(_) end,
    ["<A-k>"] = function(_) end,
    ["<A-b>"] = function(_) end,
    ["-"] = { "actions.parent", mode = "n" },
    ["<bs>"] = { "actions.parent", mode = "n" },
    ["q"] = { callback = close_oil, desc = "Close", mode = "n" },
    ["<C-f>"] = "actions.preview_scroll_down",
    ["<C-b>"] = "actions.preview_scroll_up",
    ["."] = { callback = set_nvim_root, desc = "Set Neovim root here", mode = "n" },
    ["`"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
    ["gs"] = { "actions.change_sort", mode = "n" },
    ["gx"] = "actions.open_external",
    ["oo"] = { callback = open_ghostty, desc = "Open Ghostty here", mode = "n" },
    ["O"] = { callback = open_in_files, desc = "Open in file manager", mode = "n" },
    ["gy"] = { callback = yank_path, desc = "Yank path", mode = "n" },
    ["H"] = { "actions.toggle_hidden", mode = "n" },
    ["g\\"] = { "actions.toggle_trash", mode = "n" },
    ["<leader>rr"] = "actions.refresh",
    ["gd"] = {
      desc = "Toggle file detail view",
      callback = function()
        detail = not detail
        if detail then
          oil.set_columns(detail_columns)
        else
          oil.set_columns(compact_columns)
        end
      end,
    },
    ["f"] = { callback = search_here, desc = "Search", mode = "n" },
    ["<A-f>"] = { callback = search_here, desc = "Search", mode = "n" },
    ["<A-F>"] = { callback = search_here, desc = "Search", mode = "n" },
    ["<A-q>"] = { callback = search_here, desc = "Search", mode = "n" },
  },
}

-- Oil is not the default file explorer (`default_file_explorer = false`).
-- Neovim can still put a directory listing in an editor window (oil, netrw, or
-- a raw directory buffer) after closing the last file, `:e dir`, etc.
-- Replace those accidental listings with the dashboard. Intentional oil via
-- `<A-o>` sets `state_oil_opened` and is left alone.
vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function(ev)
    if vim.g.state_oil_opened then
      return
    end
    local buf = ev.buf
    local ft = vim.bo[buf].filetype
    if ft == "neo-tree" or ft == "dashboard" then
      return
    end
    local name = vim.api.nvim_buf_get_name(buf)
    if ft ~= "oil" and ft ~= "netrw" and not (name ~= "" and vim.fn.isdirectory(name) == 1) then
      return
    end
    -- Oil/netrw finish setup after BufWinEnter; wait so we replace the shown buffer.
    vim.schedule(function()
      -- Toggle may have opened oil in the meantime, or this buffer may already be gone.
      if vim.g.state_oil_opened or not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      -- Same listing can be in several windows; swap each of them to the dashboard.
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == buf then
          show_empty_in(win)
        end
      end
    end)
  end,
})

return M
