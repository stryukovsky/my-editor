local trouble = require "trouble"

local function toggle_severity(view)
  local f = view:get_filter "severity"
  local severity = ((f and f.filter.severity or 0) + 1) % 5
  view:filter({ severity = severity }, {
    id = "severity",
    template = "{hl:Title}Filter:{hl} {severity}",
    del = severity == 0,
  })
end

local function terminalwise_jump(view, ctx)
  local prev_win = vim.fn.win_getid(vim.fn.winnr "#")
  if prev_win ~= 0 and vim.api.nvim_win_is_valid(prev_win) then
    local buf = vim.api.nvim_win_get_buf(prev_win)
    if vim.bo[buf].buftype == "terminal" then
      vim.notify("Switch away from terminal before jumping", vim.log.levels.WARN)
      return
    end
  end

  if ctx and ctx.item then
    view:jump(ctx.item)
  elseif ctx and ctx.node then
    view:fold(ctx.node)
  end
end

local function review_jump(view, ctx)
  local item = ctx and ctx.item
  if not item then
    return
  end
  require("configs.minidiff_review").jump(view, item)
end

local function review_noop() end

---@diagnostic disable-next-line: missing-fields
trouble.setup {
  warn_no_results = false, -- show a warning when there are no results
  open_no_results = false, -- open the trouble window when there are no results
  auto_preview = false,
  modes = {
    global_results = {
      desc = "Search results with file and position",
      source = "telescope",
      title = "{hl:Title} Search Results{hl}    {count} entries found ",
      format = "{padded_filename} {padded_pos}   {text:ts}",
    },

    telescope_files = {
      desc = "Files found by name",
      source = "telescope",
      title = "{hl:Title} Files{hl}    {count} entries found ",
      format = "{file_icon} {padded_filename}",
    },
    file_results = {
      desc = "File results with just position",
      source = "telescope",
      title = "{hl:Title} Search Results{hl}    {count} entries found ",
      format = "{padded_pos}   {text:ts}",
    },
    minidiff_review = {
      desc = "MiniDiff review files",
      source = "minidiff_review",
      title = "{hl:Title} Review{hl}  {review_range}  {count} files",
      format = "{review_status} {review_path} {review_stats}",
      auto_preview = false,
      auto_refresh = false,
      follow = false,
      focus = true,
      max_items = 2000,
      keys = {
        ["<cr>"] = review_jump,
        l = review_jump,
        o = review_jump,
        ["<2-leftmouse>"] = review_jump,
        ["<c-s>"] = review_jump,
        ["<c-v>"] = review_jump,
        p = review_noop,
        P = review_noop,
        q = function()
          require("configs.minidiff_review").finish_review { force = true }
        end,
      },
    },
  },
  formatters = {
    padded_filename = function(ctx)
      local filename = vim.fn.fnamemodify(ctx.item.filename, ":p:~:.") -- basename
      return {
        text = string.format("%-50s", filename),
      }
    end,
    padded_pos = function(ctx)
      local pos = string.format("%d:%d", ctx.item.pos[1], ctx.item.pos[2] + 1)
      return {
        text = string.format("%-6s", pos),
      }
    end,
    review_range = function()
      local current = require("configs.minidiff_review").session()
      if not current then
        return { text = "" }
      end
      return { text = current.old_name .. " → " .. current.new_name, hl = "Comment" }
    end,
    review_status = function(ctx)
      local file = ctx.item.item or {}
      local hl = ({
        A = "DiffAdd",
        D = "DiffDelete",
        M = "DiffChange",
        T = "DiffChange",
        R = "Comment",
        C = "Comment",
      })[file.kind] or "Normal"
      return { text = string.format("%-5s", file.status or ""), hl = hl }
    end,
    review_path = function(ctx)
      local file = ctx.item.item or {}
      return {
        text = file.label or ctx.item.filename,
        hl = file.clickable and "TroubleText" or "Comment",
      }
    end,
    review_stats = function(ctx)
      local file = ctx.item.item or {}
      return { text = file.stats or "", hl = "Comment" }
    end,
  },
  keys = {
    ["?"] = "help",
    r = "refresh",
    R = "toggle_refresh",
    q = "close",
    o = "jump_close",
    ["<esc>"] = "cancel",
    ["<cr>"] = terminalwise_jump,
    ["l"] = terminalwise_jump,
    ["h"] = "fold_close",
    ["<2-leftmouse>"] = terminalwise_jump,
    ["<c-s>"] = "jump_split",
    ["<c-v>"] = "jump_vsplit",
    -- go down to next item (accepts count)
    -- j = "next",
    ["}"] = "next",
    ["]]"] = "next",
    -- go up to prev item (accepts count)
    -- k = "prev",
    ["{"] = "prev",
    ["[["] = "prev",
    dd = "delete",
    d = { action = "delete", mode = "v" },
    i = "inspect",
    p = "preview",
    P = "toggle_preview",
    zo = "fold_open",
    zO = "fold_open_recursive",
    zc = "fold_close",
    zC = "fold_close_recursive",
    za = "fold_toggle",
    zA = "fold_toggle_recursive",
    zm = "fold_more",
    zM = "fold_close_all",
    zr = "fold_reduce",
    zR = "fold_open_all",
    zx = "fold_update",
    zX = "fold_update_all",
    zn = "fold_disable",
    zN = "fold_enable",
    zi = "fold_toggle_enable",
    gb = { -- example of a custom action that toggles the active view filter
      action = function(view)
        view:filter({ buf = 0 }, { toggle = true })
      end,
      desc = "Toggle Current Buffer Filter",
    },
    s = { -- example of a custom action that toggles the severity
      action = toggle_severity,
      desc = "Toggle Severity Filter",
    },
    f = { -- example of a custom action that toggles the severity
      action = toggle_severity,
      desc = "Toggle Severity Filter",
    },
  },
}
