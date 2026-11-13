local M = {}
local store_module = require "moonshine.jumper.store"
local namespace = vim.api.nvim_create_namespace "moonshine.jumper.positions"
local store
local tracked = {} -- buffer -> mark name -> extmark id
local line_index = {} -- buffer -> cached line -> letters
local dirty = {}
local anchor

local function warn(message)
  vim.notify(message, vim.log.levels.WARN, { title = "Jumper" })
end

local function path_for(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return nil
  end
  return vim.fs.normalize(vim.fn.fnamemodify(name, ":p"))
end

local function clamp(buf, row, col)
  row = math.min(math.max(row, 1), vim.api.nvim_buf_line_count(buf))
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
  return row, math.min(col, #line)
end

local function redraw()
  vim.cmd "redrawstatus"
end

local function invalidate(buf)
  dirty[buf] = true
  redraw()
end

local function position(name)
  local entry = store.marks[name]
  if not entry then
    return nil
  end
  for buf, names in pairs(tracked) do
    if names[name] and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) and path_for(buf) == entry.path then
      local pos = vim.api.nvim_buf_get_extmark_by_id(buf, namespace, names[name], {})
      if #pos == 2 then
        return { path = entry.path, row = pos[1] + 1, col = pos[2] }
      end
    end
  end
  return entry
end

local function reconcile(buf)
  if not store or not tracked[buf] or not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  local changed = false
  for name in pairs(tracked[buf]) do
    local pos = position(name)
    local entry = store.marks[name]
    if entry and pos and (entry.row ~= pos.row or entry.col ~= pos.col) then
      entry.row, entry.col = pos.row, pos.col
      changed = true
    end
  end
  if changed then
    local ok, err = store:save()
    if not ok then
      warn(err)
    end
  end
end

local function untrack(buf)
  if not tracked[buf] then
    return
  end
  reconcile(buf)
  tracked[buf] = nil
  line_index[buf] = nil
  dirty[buf] = nil
end

local function hydrate(buf)
  if not store or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  local path = path_for(buf)
  if not path then
    return
  end
  tracked[buf] = tracked[buf] or {}
  local names = tracked[buf]
  for name, entry in pairs(store.marks) do
    if entry.path == path and not names[name] then
      local row, col = clamp(buf, entry.row, entry.col)
      names[name] = vim.api.nvim_buf_set_extmark(buf, namespace, row - 1, col, { right_gravity = false })
      if row ~= entry.row or col ~= entry.col then
        entry.row, entry.col = row, col
        if store.writable then
          local ok, err = store:save()
          if not ok then
            warn(err)
          end
        end
      end
    end
  end
  if not vim.b[buf].jumper_attached then
    vim.b[buf].jumper_attached = true
    vim.api.nvim_buf_attach(buf, false, {
      on_lines = function()
        invalidate(buf)
      end,
      on_detach = function()
        tracked[buf] = nil
        line_index[buf] = nil
        dirty[buf] = nil
        if vim.api.nvim_buf_is_valid(buf) then
          vim.b[buf].jumper_attached = nil
        end
      end,
    })
  end
  invalidate(buf)
end

local function replace_extmarks(name, path, row, col)
  for buf, names in pairs(tracked) do
    if names[name] and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_del_extmark(buf, namespace, names[name])
      names[name] = nil
    end
    if vim.api.nvim_buf_is_loaded(buf) and path_for(buf) == path then
      local r, c = clamp(buf, row, col)
      names[name] = vim.api.nvim_buf_set_extmark(buf, namespace, r - 1, c, { right_gravity = false })
    end
    dirty[buf] = true
  end
  redraw()
end

function M.setup(opts)
  opts = opts or {}
  store = store_module.new(opts.path)
  tracked, line_index, dirty, anchor = {}, {}, {}, nil
  local ok, err = store:load()
  if not ok then
    warn(err)
  end
  local group = vim.api.nvim_create_augroup("MoonshineJumper", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufEnter" }, {
    group = group,
    callback = function(args)
      hydrate(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(args)
      reconcile(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete" }, {
    group = group,
    callback = function(args)
      untrack(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      for buf in pairs(tracked) do
        reconcile(buf)
      end
    end,
  })
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    hydrate(buf)
  end
end

function M.set(name)
  if not store then
    return false
  end
  local buf = vim.api.nvim_get_current_buf()
  local path = path_for(buf)
  if not path or not vim.bo[buf].modifiable then
    warn "Cannot set a jumper mark in this buffer"
    return false
  end
  hydrate(buf)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local old = position(name)
  local ok, err = store:set(name, { path = path, row = cursor[1], col = cursor[2] })
  if not ok then
    warn(err)
    return false
  end
  replace_extmarks(name, path, cursor[1], cursor[2])
  if old and old.path ~= path then
    redraw()
  end
  return true
end

function M.get(name)
  return store and position(name) or nil
end

function M.letters(buf, row)
  if not store or not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) or not path_for(buf) then
    return ""
  end
  if dirty[buf] or not line_index[buf] then
    local index = {}
    local names = vim.tbl_keys(store.marks)
    table.sort(names)
    for _, name in ipairs(names) do
      local pos = position(name)
      if pos.path == path_for(buf) then
        index[pos.row] = (index[pos.row] or "") .. name
      end
    end
    line_index[buf] = index
    dirty[buf] = nil
  end
  return line_index[buf][row] or ""
end

function M.jump(name)
  if not store then
    return false
  end
  local dest = position(name)
  if not dest then
    warn("Mark " .. name .. " is not set")
    return false
  end
  if not vim.uv.fs_stat(dest.path) then
    warn("Mark " .. name .. " points to a missing file: " .. dest.path)
    return false
  end
  if path_for(vim.api.nvim_get_current_buf()) ~= dest.path then
    local ok, err = pcall(vim.cmd.edit, { args = { dest.path } })
    if not ok then
      warn("Cannot open mark " .. name .. ": " .. tostring(err))
      return false
    end
  end
  local buf = vim.api.nvim_get_current_buf()
  hydrate(buf)
  dest = position(name) or dest
  local row, col = clamp(buf, dest.row, dest.col)
  vim.api.nvim_win_set_cursor(0, { row, col })
  anchor = name
  return true
end

function M.delete(name)
  if not store then
    return false
  end
  local ok, err = store:delete(name)
  if not ok then
    warn(err)
    return false
  end
  for buf, names in pairs(tracked) do
    if names[name] and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_del_extmark(buf, namespace, names[name])
    end
    names[name] = nil
    dirty[buf] = true
  end
  if anchor == name then
    anchor = nil
  end
  redraw()
  return true
end

function M.delete_line()
  local path = path_for(vim.api.nvim_get_current_buf())
  if not path then
    return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  for name in pairs(store.marks) do
    local pos = position(name)
    if pos.path == path and pos.row == row then
      M.delete(name)
    end
  end
end

function M.delete_file()
  local path = path_for(vim.api.nvim_get_current_buf())
  if not path then
    return
  end
  for name, entry in pairs(store.marks) do
    if entry.path == path then
      M.delete(name)
    end
  end
end

function M.add_next()
  if not store then
    return false
  end
  local highest = string.byte("a") - 1
  local occupied = 0
  for name in pairs(store.marks) do
    highest = math.max(highest, name:byte())
    occupied = occupied + 1
  end
  if occupied == 26 then
    warn "All jumper mark names are in use"
    return false
  end
  for step = 1, 26 do
    local code = string.byte("a") + (highest - string.byte("a") + step) % 26
    local name = string.char(code)
    if not store.marks[name] then
      return M.set(name) and name or false
    end
  end
  return false
end

function M.delete_all()
  if not store then
    return false
  end
  for name in pairs(store.marks) do
    if not M.delete(name) then
      return false
    end
  end
  return true
end

function M.navigate(direction, count)
  if not store then
    return false
  end
  local names = vim.tbl_keys(store.marks)
  table.sort(names)
  if #names == 0 then
    warn "No jumper marks"
    return false
  end
  local current = anchor
  if not current or not store.marks[current] then
    local buf = vim.api.nvim_get_current_buf()
    local path = path_for(buf)
    local row = vim.api.nvim_win_get_cursor(0)[1]
    current = nil
    for _, name in ipairs(names) do
      local pos = position(name)
      if pos.path == path and pos.row == row then
        current = name
        break
      end
    end
  end
  local index
  for i, name in ipairs(names) do
    if name == current then
      index = i
      break
    end
  end
  local steps = count or 1
  local target = index and names[(index - 1 + direction * steps) % #names + 1]
    or names[direction == 1 and ((steps - 1) % #names + 1) or ((#names - steps) % #names + 1)]
  if not M.jump(target) then
    return false
  end
  require("moonshine.utils.navigation_repeat").set(function()
    M.navigate(1)
  end, function()
    M.navigate(-1)
  end, "jumper mark")
  return true
end

return M
