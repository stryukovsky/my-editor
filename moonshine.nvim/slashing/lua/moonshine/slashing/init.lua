local navigation_repeat = require "utils.navigation_repeat"

local M = {}

-- `/` and `<A-f>` stay on the buffer where the search started.
-- `hlsearch` is global, so matches are drawn with window-local `matchadd`
-- and n/N return to this buffer, continuing from its cursor.
---@class SlashSession
---@field buf integer
---@field win integer|nil
---@field cursor integer[]|nil -- {lnum, col} 0-based col, last position in `buf`
---@field pattern string
---@field forward boolean
---@field visual boolean
---@field hl boolean

---@type SlashSession|nil
local session
local matches = {} ---@type table<integer, integer>
local shown_pattern ---@type string|nil
local follow = true
local lens_pending = false
local lens_ns = vim.api.nvim_create_namespace "slash_search_lens"

local SKIP_FT = {
  ["neo-tree"] = true,
  oil = true,
  notify = true,
  TelescopePrompt = true,
  TelescopeResults = true,
  lazy = true,
  mason = true,
  trouble = true,
  qf = true,
}

local group = vim.api.nvim_create_augroup("SlashSearchBuffer", { clear = true })

local function stop_lens_plugin()
  pcall(function()
    require("hlslens").stop()
  end)
end

local function start_lens_plugin()
  pcall(function()
    require("hlslens").start()
  end)
end

local function clear_lens(buf)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_clear_namespace, buf, lens_ns, 0, -1)
  end
end

local function clear_matches()
  for win, id in pairs(matches) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.fn.matchdelete, id, win)
    end
  end
  matches = {}
  shown_pattern = nil
end

---@param win integer
---@param pattern string
---@return integer|nil
local function add_match(win, pattern)
  local ok, id = pcall(vim.fn.matchadd, "Search", pattern, 10, -1, { window = win })
  if ok and type(id) == "number" and id > 0 then
    return id
  end
end

---@return integer[]
local function session_windows()
  if not session or not vim.api.nvim_buf_is_valid(session.buf) then
    return {}
  end
  local list = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == session.buf then
      if not session.visual or win == session.win then
        list[#list + 1] = win
      end
    end
  end
  return list
end

local function sync_highlights()
  if not session or not session.hl or session.pattern == "" or not vim.api.nvim_buf_is_valid(session.buf) then
    clear_matches()
    return
  end
  if shown_pattern ~= session.pattern then
    clear_matches()
    shown_pattern = session.pattern
  end
  local seen = {}
  for _, win in ipairs(session_windows()) do
    seen[win] = true
    if not matches[win] then
      local id = add_match(win, session.pattern)
      if id then
        matches[win] = id
      end
    end
  end
  for win, id in pairs(matches) do
    if not seen[win] then
      if vim.api.nvim_win_is_valid(win) then
        pcall(vim.fn.matchdelete, id, win)
      end
      matches[win] = nil
    end
  end
end

local function update_lens()
  if not session or not session.hl or not vim.api.nvim_buf_is_valid(session.buf) then
    if session then
      clear_lens(session.buf)
    end
    return
  end
  local buf = session.buf
  clear_lens(buf)
  local win = session.win
  if not (win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf) then
    win = session_windows()[1]
  end
  if not win then
    return
  end
  if vim.api.nvim_get_current_buf() == buf then
    win = vim.api.nvim_get_current_win()
    session.win = win
    session.cursor = vim.api.nvim_win_get_cursor(win)
  end
  local cursor = session.cursor or vim.api.nvim_win_get_cursor(win)
  local ok, result = pcall(vim.api.nvim_win_call, win, function()
    return vim.fn.searchcount {
      pattern = session.pattern,
      recompute = true,
      maxcount = 999,
      timeout = 60,
    }
  end)
  if not ok or type(result) ~= "table" or (result.total or 0) == 0 then
    return
  end
  local label = (" [%d/%d%s]"):format(result.current or 0, result.total or 0, result.incomplete ~= 0 and "+" or "")
  pcall(vim.api.nvim_buf_set_extmark, buf, lens_ns, cursor[1] - 1, 0, {
    virt_text = { { label, "HlSearchLensNear" } },
    virt_text_pos = "eol",
    priority = 200,
  })
end

local function schedule_lens()
  if lens_pending then
    return
  end
  lens_pending = true
  vim.defer_fn(function()
    lens_pending = false
    update_lens()
  end, 60)
end

local function remember_cursor()
  if not follow or not session or not vim.api.nvim_buf_is_valid(session.buf) then
    return
  end
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= session.buf then
    return
  end
  session.cursor = vim.api.nvim_win_get_cursor(win)
  session.win = win
end

---@param fn fun()
---@return boolean
local function without_global_hl(fn)
  local prev = vim.o.hlsearch
  vim.o.hlsearch = false
  local ok = pcall(fn)
  vim.o.hlsearch = prev
  return ok
end

---@param win integer
---@param buf integer
---@return boolean
local function can_host(win, buf)
  if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_config(win).relative ~= "" then
    return false
  end
  if vim.bo[buf].buftype ~= "" then
    return vim.api.nvim_win_get_buf(win) == buf
  end
  local host = vim.api.nvim_win_get_buf(win)
  if vim.bo[host].buftype ~= "" or SKIP_FT[vim.bo[host].filetype] then
    return false
  end
  return true
end

---@param win integer
---@param cursor integer[]|nil
local function restore_cursor(win, cursor)
  if not cursor then
    return
  end
  pcall(vim.api.nvim_win_set_cursor, win, cursor)
end

---@return boolean
local function focus_session()
  if not session or not vim.api.nvim_buf_is_valid(session.buf) then
    if session then
      clear_lens(session.buf)
    end
    session = nil
    clear_matches()
    return false
  end
  local buf = session.buf
  if session.visual and session.win and vim.api.nvim_win_is_valid(session.win) and vim.api.nvim_win_get_buf(session.win) == buf then
    if vim.api.nvim_get_current_win() ~= session.win then
      vim.api.nvim_set_current_win(session.win)
    end
    return true
  end
  if vim.api.nvim_get_current_buf() == buf then
    session.win = vim.api.nvim_get_current_win()
    return true
  end
  local win = session.win
  if win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
    vim.api.nvim_set_current_win(win)
    return true
  end
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(w).relative == "" and vim.api.nvim_win_get_buf(w) == buf then
      session.win = w
      vim.api.nvim_set_current_win(w)
      return true
    end
  end
  local target
  local cur = vim.api.nvim_get_current_win()
  if can_host(cur, buf) then
    target = cur
  else
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if can_host(w, buf) then
        target = w
        break
      end
    end
  end
  if target then
    vim.api.nvim_set_current_win(target)
  else
    vim.cmd "split"
  end
  if not pcall(vim.api.nvim_set_current_buf, buf) then
    return false
  end
  session.win = vim.api.nvim_get_current_win()
  restore_cursor(session.win, session.cursor)
  return vim.api.nvim_get_current_buf() == buf
end

local function bind_repeat()
  navigation_repeat.set(function()
    M.jump "n"
  end, function()
    M.jump "N"
  end, "search match")
end

---@param key string
---@return boolean
function M.jump(key)
  local use_session = (key == "n" or key == "N") and session ~= nil and vim.api.nvim_buf_is_valid(session.buf)
  if (key == "n" or key == "N") and session and not vim.api.nvim_buf_is_valid(session.buf) then
    clear_lens(session.buf)
    session = nil
    clear_matches()
  end
  if use_session then
    if not focus_session() then
      return false
    end
    vim.v.searchforward = session.forward and 1 or 0
    if vim.fn.getreg "/" ~= session.pattern then
      vim.fn.setreg("/", session.pattern)
    end
  end
  local ok = without_global_hl(function()
    vim.cmd("normal! " .. vim.v.count1 .. key)
  end)
  if not ok then
    return false
  end
  if use_session and session then
    remember_cursor()
    session.hl = true
    -- Restoring 'hlsearch' turns v:hlsearch back on. Drop the global highlight.
    vim.cmd "nohlsearch"
    stop_lens_plugin()
    sync_highlights()
    schedule_lens()
    return true
  end
  if session and key ~= "n" and key ~= "N" then
    clear_lens(session.buf)
    clear_matches()
    session = nil
  end
  vim.o.hlsearch = true
  vim.v.hlsearch = 1
  start_lens_plugin()
  return true
end

--- Make the current pattern the repeat target for n/N and ; / <A-;>.
--- `opts.buf` keeps the search on the buffer where `/` or `<A-f>` started.
---@param opts? { buf?: integer, win?: integer, cursor?: integer[], pattern?: string, forward?: boolean, visual?: boolean }
function M.activate(opts)
  opts = opts or {}
  if opts.buf and vim.api.nvim_buf_is_valid(opts.buf) then
    if session and session.buf ~= opts.buf then
      clear_lens(session.buf)
    end
    clear_matches()
    session = {
      buf = opts.buf,
      win = opts.win,
      cursor = opts.cursor,
      pattern = opts.pattern or vim.fn.getreg "/",
      forward = opts.forward ~= false,
      visual = opts.visual == true,
      hl = true,
    }
    vim.cmd "nohlsearch"
    stop_lens_plugin()
    sync_highlights()
    schedule_lens()
  else
    if session then
      clear_lens(session.buf)
    end
    session = nil
    clear_matches()
    vim.o.hlsearch = true
    vim.v.hlsearch = 1
    start_lens_plugin()
  end
  bind_repeat()
end

--- Jump to the first match of `query` from the saved view (like `/` / `?`).
---@param win integer|nil
---@param buf integer
---@param view table
---@param query string
---@param backward boolean
---@return integer|nil
local function goto_first_match(win, buf, view, query, backward)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end
  if not (win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf) then
    win = nil
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(w) == buf and vim.api.nvim_win_get_config(w).relative == "" then
        win = w
        break
      end
    end
  end
  if not win then
    local cur = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(cur).relative ~= "" then
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(w).relative == "" then
          cur = w
          break
        end
      end
    end
    vim.api.nvim_set_current_win(cur)
    if not pcall(vim.api.nvim_set_current_buf, buf) then
      return nil
    end
    win = vim.api.nvim_get_current_win()
  elseif vim.api.nvim_get_current_win() ~= win then
    vim.api.nvim_set_current_win(win)
  end
  without_global_hl(function()
    vim.api.nvim_win_call(win, function()
      vim.fn.winrestview(view)
      vim.v.searchforward = backward and 0 or 1
      -- `c`: accept match at cursor (same as `/` / `?`).
      pcall(vim.fn.search, query, backward and "bc" or "c")
    end)
  end)
  vim.cmd "nohlsearch"
  return win
end

---Ask for a pattern in the float input. Highlight while typing, do not move.
---`<CR>` jumps to the first match in the buffer where the prompt opened.
---`<Esc>` drops this search. The float shows `found: N` beside the pattern.
---@param opts? { prompt?: string, visual?: boolean, backward?: boolean }
function M.prompt(opts)
  opts = opts or {}
  follow = false
  local backward = opts.backward == true
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local view = vim.fn.winsaveview()
  local prev_reg = vim.fn.getreg "/"
  local prev_regtype = vim.fn.getregtype "/"
  local prev_hl = vim.v.hlsearch == 1 or vim.v.hlsearch == true
  local prev_session = session
  local prev_session_hl = session and session.hl or false
  local live = {} ---@type table<integer, integer>

  if session then
    session.hl = false
    clear_matches()
    clear_lens(session.buf)
  end

  local function restore_place()
    if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then
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
    for live_win, id in pairs(live) do
      if vim.api.nvim_win_is_valid(live_win) then
        pcall(vim.fn.matchdelete, id, live_win)
      end
    end
    live = {}
  end

  -- matchadd ignores 'ignorecase'/'smartcase'. \c / \C make the preview, the
  -- jump, and n/N agree: lowercase ignores case, any uppercase matches case.
  local function with_smartcase(pattern)
    if pattern:find "\\[cC]" then
      return pattern
    end
    if vim.fn.match(pattern, [[\u]]) >= 0 then
      return "\\C" .. pattern
    end
    return "\\c" .. pattern
  end

  local function query_for(value)
    local pattern = with_smartcase(value)
    if opts.visual then
      return "\\%V" .. pattern
    end
    return pattern
  end

  local function restore_prev()
    clear_live()
    vim.fn.setreg("/", prev_reg, prev_regtype)
    if prev_session then
      session = prev_session
      session.pattern = prev_reg
      session.hl = prev_session_hl and prev_reg ~= ""
      if session.hl then
        vim.cmd "nohlsearch"
        stop_lens_plugin()
        sync_highlights()
        schedule_lens()
      else
        clear_matches()
        clear_lens(session.buf)
        vim.cmd "nohlsearch"
      end
    elseif prev_hl and prev_reg ~= "" then
      session = nil
      clear_matches()
      vim.o.hlsearch = true
      vim.v.hlsearch = 1
      start_lens_plugin()
    else
      session = nil
      clear_matches()
      vim.cmd "nohlsearch"
      stop_lens_plugin()
    end
    restore_place()
  end

  ---@return integer? count
  ---@return boolean? capped true when the scan hit its limit
  local function match_count(query)
    if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then
      return nil
    end
    local ok, result = pcall(vim.api.nvim_win_call, win, function()
      return vim.fn.searchcount {
        pattern = query,
        recompute = true,
        maxcount = 999,
        timeout = 60,
      }
    end)
    if not ok or type(result) ~= "table" then
      return nil
    end
    return result.total or 0, result.incomplete ~= 0
  end

  ---@param value string
  ---@return integer? count
  ---@return boolean? capped
  local function highlight(value)
    clear_live()
    if value == "" then
      vim.cmd "nohlsearch"
      restore_place()
      return
    end
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local query = query_for(value)
    local eventignore = vim.o.eventignore
    vim.o.eventignore = "all"
    vim.cmd "nohlsearch"
    for _, live_win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(live_win) == buf and (not opts.visual or live_win == win) then
        local id = add_match(live_win, query)
        if id then
          live[live_win] = id
        end
      end
    end
    vim.o.eventignore = eventignore
    local count, capped = match_count(query)
    restore_place()
    return count, capped
  end

  local ok, err = pcall(vim.ui.input, {
    prompt = opts.prompt or "Search",
    on_input = highlight,
    virtual_text_mode = "slash_search",
  }, function(value)
    local finished, finish_err = xpcall(function()
      if value == nil or value == "" then
        restore_prev()
        return
      end
      local query = query_for(value)
      vim.fn.setreg("/", query)
      vim.fn.histadd("search", query)
      clear_live()
      local landed = goto_first_match(win, buf, view, query, backward)
      local cursor = { view.lnum, view.col }
      local search_win = landed or win
      if search_win and vim.api.nvim_win_is_valid(search_win) and vim.api.nvim_win_get_buf(search_win) == buf then
        cursor = vim.api.nvim_win_get_cursor(search_win)
      end
      M.activate {
        buf = buf,
        win = search_win,
        cursor = cursor,
        pattern = query,
        forward = not backward,
        visual = opts.visual == true,
      }
    end, debug.traceback)
    follow = true
    if not finished then
      error(finish_err, 0)
    end
  end)
  if not ok then
    follow = true
    restore_prev()
    error(err, 0)
  end
end

--- Drop slash highlight. Keep the pattern and the origin buffer so n/N and
--- ; / <A-;> search there again.
function M.forget()
  if session then
    session.hl = false
    clear_lens(session.buf)
  end
  clear_matches()
  vim.cmd "nohlsearch"
  stop_lens_plugin()
end

vim.api.nvim_create_autocmd("BufWinLeave", {
  group = group,
  callback = function()
    local win = vim.api.nvim_get_current_win()
    local id = matches[win]
    if not id then
      return
    end
    pcall(vim.fn.matchdelete, id, win)
    matches[win] = nil
  end,
})

vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "WinClosed" }, {
  group = group,
  callback = function()
    if session and session.hl then
      sync_highlights()
    end
  end,
})

vim.api.nvim_create_autocmd({ "CursorMoved", "BufLeave" }, {
  group = group,
  callback = function(ev)
    remember_cursor()
    if ev.event == "CursorMoved" and session and session.hl and vim.api.nvim_get_current_buf() == session.buf then
      schedule_lens()
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
  group = group,
  callback = function(ev)
    if session and ev.buf == session.buf then
      clear_matches()
      session = nil
    end
  end,
})

return M
