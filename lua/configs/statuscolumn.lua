local builtin = require "statuscol.builtin"

-- Virtual lines belong to the cursor buffer line but are separate screen rows.
-- Do not inherit the cursor-line status-column highlights for those rows.
local function normal_virtual_line_args(args)
  if args.virtnum == 0 then
    return args
  end
  return vim.tbl_extend("force", {}, args, { cul = false, relnum = 1 })
end

local function padded_lnum(args, segment)
  local padded_args = vim.tbl_extend(
    "force",
    {},
    normal_virtual_line_args(args),
    { nuw = math.max(4, args.nuw) }
  )
  return builtin.lnumfunc(padded_args, segment)
end

local function foldfunc(args, segment)
  return builtin.foldfunc(normal_virtual_line_args(args), segment)
end

local function signfunc(args, segment)
  return builtin.signfunc(normal_virtual_line_args(args), segment)
end

local function markfunc(args)
  if args.virtnum ~= 0 then
    return " "
  end
  local letters = require("moonshine.jumper").letters(args.buf, args.lnum)
  return letters ~= "" and letters or " "
end

require("statuscol").setup {
  setopt = true, -- Whether to set the 'statuscolumn' option, may be set to false for those who
  -- want to use the click handlers in their own 'statuscolumn': _G.Sc[SFL]a().
  -- Although I recommend just using the segments field below to build your
  -- statuscolumn to benefit from the performance optimizations in this plugin.
  -- builtin.lnumfunc number string options
  thousands = ".", -- or line number thousands separator string ("." / ",")
  relculright = true, -- whether to right-align the cursor line number with 'relativenumber' set
  -- Builtin 'statuscolumn' options
  ft_ignore = require "moonshine.utils.technical_ui_filetypes", -- Lua table with 'filetype' values for which 'statuscolumn' will be unset
  bt_ignore = { "terminal" }, -- Lua table with 'buftype' values for which 'statuscolumn' will be unset
  -- Default segments (fold -> sign -> line number + separator), explained below
  segments = {
    {
      text = { foldfunc },
      click = "v:lua.ScFa",
      -- auto = true,
    },
    {
      text = { padded_lnum, " " },
      condition = { true, builtin.not_empty },
      click = "v:lua.ScLa",
      -- auto = true,
    },
    {
      sign = {
        namespace = { "MiniDiffViz" },
        wrap = true,
      },
      text = { signfunc },
      click = "v:lua.ScSa",
    },
    {
      sign = {
        name = { ".*" },
        namespace = { ".*" },
        wrap = false,
      },
      text = { signfunc },
      click = "v:lua.ScSa",
    },
    {
      text = { markfunc },
    },
    {
      text = { "┊" },
      hl = "StatusColumnDivider",
    },
  },
  clickmod = "c", -- modifier used for certain actions in the builtin clickhandlers:
  -- "a" for Alt, "c" for Ctrl and "m" for Meta.
  clickhandlers = { -- builtin click handlers, keys are pattern matched
    Lnum = builtin.lnum_click,
    FoldClose = builtin.foldclose_click,
    FoldOpen = builtin.foldopen_click,
    FoldOther = builtin.foldother_click,
    DapBreakpointRejected = builtin.toggle_breakpoint,
    DapBreakpoint = builtin.toggle_breakpoint,
    DapBreakpointCondition = builtin.toggle_breakpoint,
    ["diagnostic/signs"] = builtin.diagnostic_click,
    MiniDiffViz = function(args)
      local minidiff = require "moonshine.diff"
      if args.button == "l" then
        minidiff.preview()
      elseif args.button == "m" then
        minidiff.reset_hunk()
      end
    end,
  },
}

-- An empty statuscolumn still reserves space for folds, signs and line numbers.
local ignored_filetypes = require "moonshine.utils.technical_ui_filetypes"
local hidden_gutters = {}
local gutter_options =
  { "statuscolumn", "foldcolumn", "signcolumn", "number", "relativenumber" }

local function update_gutters()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local bo = vim.bo[buf]
    local hide = not bo.modifiable
      or bo.buftype ~= ""
      or vim.tbl_contains(ignored_filetypes, bo.filetype)
    if hide then
      if not hidden_gutters[win] then
        local saved = {}
        for _, option in ipairs(gutter_options) do
          saved[option] = vim.api.nvim_get_option_value(option, { win = win, scope = "local" })
        end
        -- A split of a technical window inherits its hidden gutter options.
        if
          saved.statuscolumn == ""
          and saved.foldcolumn == "0"
          and saved.signcolumn == "no"
          and not saved.number
          and not saved.relativenumber
        then
          for _, option in ipairs(gutter_options) do
            saved[option] = vim.api.nvim_get_option_value(option, { scope = "global" })
          end
        end
        -- statuscol may already have cleared this on FileType/BufWinEnter.
        if saved.statuscolumn == "" then
          saved.statuscolumn = vim.go.statuscolumn
        end
        hidden_gutters[win] = saved
      end
      local hidden = {
        statuscolumn = "",
        foldcolumn = "0",
        signcolumn = "no",
        number = false,
        relativenumber = false,
      }
      for option, value in pairs(hidden) do
        vim.api.nvim_set_option_value(option, value, { win = win, scope = "local" })
      end
    elseif hidden_gutters[win] then
      for option, value in pairs(hidden_gutters[win]) do
        vim.api.nvim_set_option_value(option, value, { win = win, scope = "local" })
      end
      hidden_gutters[win] = nil
    end
  end
end

local gutter_group =
  vim.api.nvim_create_augroup("EditableBufferGutters", { clear = true })
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileType" }, {
  group = gutter_group,
  callback = function()
    vim.schedule(update_gutters)
  end,
})
vim.api.nvim_create_autocmd("OptionSet", {
  group = gutter_group,
  pattern = { "modifiable", "buftype" },
  callback = function()
    vim.schedule(update_gutters)
  end,
})
vim.api.nvim_create_autocmd("WinClosed", {
  group = gutter_group,
  callback = function(args)
    hidden_gutters[tonumber(args.match)] = nil
  end,
})
vim.schedule(update_gutters)
