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
  local padded_args = vim.tbl_extend("force", {}, normal_virtual_line_args(args), { nuw = math.max(4, args.nuw) })
  return builtin.lnumfunc(padded_args, segment)
end

local function foldfunc(args, segment)
  return builtin.foldfunc(normal_virtual_line_args(args), segment)
end

local function signfunc(args, segment)
  return builtin.signfunc(normal_virtual_line_args(args), segment)
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
  ft_ignore = require "utils.technical_ui_filetypes", -- Lua table with 'filetype' values for which 'statuscolumn' will be unset
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
      local minidiff = require "configs.minidiff"
      if args.button == "l" then
        minidiff.preview()
      elseif args.button == "m" then
        minidiff.reset_hunk()
      end
    end,
  },
}
