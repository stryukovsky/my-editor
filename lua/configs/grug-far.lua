-- -- Plugin helpLine only toggles the row; filter the actions shown on it.
-- local help = require "grug-far.render.help"
-- local orig_get_help = help.getHelpVirtLines
-- local help_line_actions = {
--   Replace = 1,
--   ["Apply Next"] = 2,
--   ["Apply Prev"] = 3,
--   ["Next Input"] = 4,
--   Help = 5,
-- }
--
-- function help.getHelpVirtLines(context, actions)
--   local filtered = {}
--   for _, action in ipairs(actions) do
--     if help_line_actions[action.text] then
--       filtered[#filtered + 1] = action
--     end
--   end
--   table.sort(filtered, function(a, b)
--     return help_line_actions[a.text] < help_line_actions[b.text]
--   end)
--   return orig_get_help(context, filtered)
-- end

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


  -- No maplocalleader in this config; use leader for buffer actions.
  keymaps = {
    replace = { n = "<C-r>" },
    applyNext = { n = ";" },
    applyPrev = { n = "<A-;>" },
    abort = { n = "<C-c>" },
    qflist = { n = "<C-q>" },
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
    nextInput = { n = "<tab>" },
    prevInput = { n = "<s-tab>" },
  },

  engines = {
    astgrep = {
      -- Prefer the real binary name; bare `sg` is often shadow-utils on Linux.
      path = "ast-grep",
    },
  },
}
