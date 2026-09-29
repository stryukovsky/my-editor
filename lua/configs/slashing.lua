local navigation_repeat = require "utils.navigation_repeat"

local M = {}

---@param key string
---@return boolean
function M.jump(key)
  local ok = pcall(vim.cmd, "normal! " .. vim.v.count1 .. key)
  if ok then
    require("hlslens").start()
  end
  return ok
end

--- Make `/` matches the current repeat target for n/N and ; / <A-;>.
function M.activate()
  require("hlslens").start()
  navigation_repeat.set(function()
    M.jump "n"
  end, function()
    M.jump "N"
  end, "search match")
end

---Ask for a pattern in the float input. Highlight while typing, do not move.
---`<CR>` keeps the highlight and the cursor. `<Esc>` drops this search.
---@param opts? { prompt?: string, visual?: boolean }
function M.prompt(opts)
  opts = opts or {}
  local win = vim.api.nvim_get_current_win()
  local view = vim.fn.winsaveview()
  local prev_reg = vim.fn.getreg "/"
  local prev_regtype = vim.fn.getregtype "/"
  local prev_hl = vim.v.hlsearch == 1 or vim.v.hlsearch == true
  local match_id = nil

  local function restore_place()
    if not vim.api.nvim_win_is_valid(win) then
      return
    end
    local cursor = vim.api.nvim_win_get_cursor(win)
    if cursor[1] == view.lnum and cursor[2] == view.col then
      return
    end
    local eventignore = vim.o.eventignore
    vim.o.eventignore = "all"
    pcall(vim.api.nvim_win_call, win, function()
      vim.fn.winrestview(view)
    end)
    vim.o.eventignore = eventignore
  end

  local function clear_live()
    if not match_id then
      return
    end
    pcall(vim.fn.matchdelete, match_id, win)
    match_id = nil
  end

  local function query_for(value)
    if opts.visual then
      return "\\%V" .. value
    end
    return value
  end

  local function restore_prev()
    clear_live()
    vim.fn.setreg("/", prev_reg, prev_regtype)
    if prev_hl and prev_reg ~= "" then
      vim.o.hlsearch = true
      vim.v.hlsearch = 1
    else
      vim.cmd "nohlsearch"
    end
    restore_place()
  end

  local function highlight(value)
    clear_live()
    if value == "" then
      vim.cmd "nohlsearch"
      restore_place()
      return
    end
    if not vim.api.nvim_win_is_valid(win) then
      return
    end
    local query = query_for(value)
    local eventignore = vim.o.eventignore
    vim.o.eventignore = "all"
    vim.cmd "nohlsearch"
    pcall(vim.api.nvim_win_call, win, function()
      local ok, id = pcall(vim.fn.matchadd, "Search", query, 10)
      if ok and type(id) == "number" and id > 0 then
        match_id = id
      end
    end)
    vim.o.eventignore = eventignore
    restore_place()
  end

  vim.ui.input({
    prompt = opts.prompt or "Search",
    on_input = highlight,
  }, function(value)
    if value == nil or value == "" then
      restore_prev()
      return
    end
    local query = query_for(value)
    vim.fn.setreg("/", query)
    vim.fn.histadd("search", query)
    vim.o.hlsearch = true
    vim.v.hlsearch = 1
    clear_live()
    restore_place()
    M.activate()
    restore_place()
  end)
end

--- Drop slash highlight, the last pattern, and search as the repeat target.
function M.forget()
  vim.cmd "nohlsearch"
  pcall(function()
    require("hlslens").stop()
  end)
  vim.fn.setreg("/", "")
  if navigation_repeat.name() == "search match" then
    navigation_repeat.clear()
  end
end

return M
