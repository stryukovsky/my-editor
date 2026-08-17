local Item = require "trouble.item"

local M = {}

local function notify_changed()
  vim.api.nvim_exec_autocmds("User", { pattern = "DapBreakpointsChanged" })
end

local function walk_sessions(fn)
  local dap = require "dap"
  local function walk(session)
    if not session then
      return
    end
    fn(session)
    for _, child in pairs(session.children or {}) do
      walk(child)
    end
  end
  for _, session in pairs(dap.sessions()) do
    walk(session)
  end
end

local function sync_buf_breakpoints(bufnr)
  local bps = require "dap.breakpoints"
  local payload = bps.get(bufnr)
  if not payload[bufnr] then
    payload[bufnr] = {}
  end
  walk_sessions(function(session)
    pcall(function()
      session:set_breakpoints(payload)
    end)
  end)
end

local function breakpoint_text(bp)
  local parts = {}
  if bp.buf and vim.api.nvim_buf_is_loaded(bp.buf) then
    local ok, lines = pcall(vim.api.nvim_buf_get_lines, bp.buf, bp.line - 1, bp.line, false)
    if ok and lines[1] and lines[1] ~= "" then
      parts[#parts + 1] = lines[1]
    end
  end
  local state = bp.state or {}
  if state.verified == false then
    parts[#parts + 1] = state.message and ("Rejected: " .. state.message) or "Rejected"
  end
  if bp.condition and bp.condition ~= "" then
    parts[#parts + 1] = "Condition: " .. bp.condition
  end
  if bp.hitCondition and bp.hitCondition ~= "" then
    parts[#parts + 1] = "Hit: " .. bp.hitCondition
  end
  if bp.logMessage and bp.logMessage ~= "" then
    parts[#parts + 1] = "Log: " .. bp.logMessage
  end
  if #parts == 0 then
    return "Breakpoint"
  end
  return table.concat(parts, ", ")
end

local function collect_items(view, ctx)
  local nodes = view:selection()
  if #nodes == 0 and ctx.node then
    nodes = { ctx.node }
  end
  local items = {}
  for _, node in ipairs(nodes) do
    vim.list_extend(items, node:flatten())
  end
  return items
end

local function remove_breakpoints(view, ctx)
  local items = collect_items(view, ctx)
  if #items == 0 then
    return
  end

  local bps = require "dap.breakpoints"
  local affected = {}
  for _, item in ipairs(items) do
    local buf = item.buf
    local line = item.pos and item.pos[1]
    if buf and line and vim.api.nvim_buf_is_valid(buf) then
      bps.remove(buf, line)
      affected[buf] = true
    end
  end

  for bufnr in pairs(affected) do
    sync_buf_breakpoints(bufnr)
  end

  notify_changed()
  view:refresh()
end

M.config = {
  modes = {
    dap_breakpoints = {
      desc = "DAP breakpoints",
      source = "dap_breakpoints",
      title = "{hl:Title} Breakpoints{hl}  {count}",
      events = {
        { event = "User", pattern = "DapBreakpointsChanged" },
      },
      groups = {
        { "filename", format = "{file_icon} {filename} {count}" },
      },
      sort = { "filename", "pos" },
      format = " {text:ts} {pos}",
      keys = {
        d = { action = remove_breakpoints, desc = "Remove breakpoint", mode = { "n", "v" } },
        x = { action = remove_breakpoints, desc = "Remove breakpoint", mode = { "n", "v" } },
        dd = { action = remove_breakpoints, desc = "Remove breakpoint" },
      },
    },
  },
}

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    pattern = "DapBreakpointsChanged",
    group = vim.api.nvim_create_augroup("trouble.dap_breakpoints", { clear = true }),
    callback = function()
      local ok, View = pcall(require, "trouble.view")
      if not ok then
        return
      end
      for _, entry in ipairs(View.get { mode = "dap_breakpoints", open = true } or {}) do
        if entry.view and entry.view.refresh then
          entry.view:refresh()
        end
      end
    end,
  })
end

function M.get(cb)
  local ok, bps = pcall(require, "dap.breakpoints")
  if not ok then
    cb {}
    return
  end

  local items = {}
  for bufnr, buf_bps in pairs(bps.get()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      for _, bp in pairs(buf_bps) do
        items[#items + 1] = Item.new {
          source = "dap_breakpoints",
          buf = bufnr,
          filename = vim.api.nvim_buf_get_name(bufnr),
          pos = { bp.line, 0 },
          end_pos = { bp.line, 0 },
          item = {
            text = breakpoint_text(bp),
            line = bp.line,
            condition = bp.condition,
            logMessage = bp.logMessage,
          },
        }
      end
    end
  end
  Item.add_id(items)
  cb(items)
end

return M
