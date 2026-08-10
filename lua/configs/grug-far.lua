require("grug-far").setup {
  -- Prefer a bottom split so it behaves closer to spectre.
  windowCreationCommand = "botright split",
  startInInsertMode = true,
  transient = true,
  wrap = true,

  -- No maplocalleader in this config; use leader for buffer actions.
  keymaps = {
    replace = { n = "<leader>rr" },
    qflist = { n = "<leader>rq" },
    syncLocations = { n = "<leader>rs" },
    syncLine = { n = "<leader>rl" },
    close = { n = "q" },
    historyOpen = { n = "<leader>rt" },
    historyAdd = { n = "<leader>ra" },
    refresh = { n = "<leader>rf" },
    openLocation = { n = "<leader>ro" },
    openNextLocation = { n = "<down>" },
    openPrevLocation = { n = "<up>" },
    gotoLocation = { n = "<enter>" },
    pickHistoryEntry = { n = "<enter>" },
    abort = { n = "<leader>rb" },
    help = { n = "g?" },
    toggleShowCommand = { n = "<leader>rw" },
    swapEngine = { n = "<leader>re" },
    previewLocation = { n = "<leader>ri" },
    swapReplacementInterpreter = { n = "<leader>rx" },
    applyNext = { n = "<leader>rj" },
    applyPrev = { n = "<leader>rk" },
    syncNext = { n = "<leader>rn" },
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
