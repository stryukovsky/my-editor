local builtin = require "statuscol.builtin"

require("statuscol").setup {
  setopt = true, -- Whether to set the 'statuscolumn' option, may be set to false for those who
  -- want to use the click handlers in their own 'statuscolumn': _G.Sc[SFL]a().
  -- Although I recommend just using the segments field below to build your
  -- statuscolumn to benefit from the performance optimizations in this plugin.
  -- builtin.lnumfunc number string options
  thousands = ".", -- or line number thousands separator string ("." / ",")
  relculright = true, -- whether to right-align the cursor line number with 'relativenumber' set
  -- Builtin 'statuscolumn' options
  ft_ignore = require("utils.technical_ui_filetypes"), -- Lua table with 'filetype' values for which 'statuscolumn' will be unset
  bt_ignore = nil, -- Lua table with 'buftype' values for which 'statuscolumn' will be unset
  -- Default segments (fold -> sign -> line number + separator), explained below
  segments = {
    {
        text = { builtin.foldfunc },
        click = "v:lua.ScFa",
        -- auto = true,
    },
    {
      text = { builtin.lnumfunc, " " },
      condition = { true, builtin.not_empty },
      click = "v:lua.ScLa",
      -- auto = true,
    },
    {
      sign = {
          namespace = { "gitsigns" },
          wrap = true,
      },
      click = "v:lua.ScSa",
    },
    {
      sign = {
          name = { ".*" },
          namespace = { ".*" },
          wrap = false,
      },
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
    gitsigns = builtin.gitsigns_click,
  },
}

