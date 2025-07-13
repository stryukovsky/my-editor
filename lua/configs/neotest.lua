---@diagnostic disable-next-line: missing-fields
require("neotest").setup {
  adapters = {
    require "neotest-go",
    require "rustaceanvim.neotest",
    require "neotest-python",
    require "neotest-scala" {
      -- Command line arguments for runner
      -- Can also be a function to return dynamic values
      args = {},
      -- Runner to use. Will use bloop by default.
      -- Can be a function to return dynamic value.
      -- For backwards compatibility, it also tries to read the vim-test scala config.
      -- Possibly values bloop|sbt.
      runner = "sbt",
      -- Test framework to use. Will use utest by default.
      -- Can be a function to return dynamic value.
      -- Possibly values utest|munit|scalatest.
      framework = "scalatest",
    },
    require "neotest-jest" {
      jestCommand = "npm test --",
    },
  },
  summary = {
    animated = true,
    count = true,
    enabled = true,
    expand_errors = true,
    follow = true,
    mappings = {
      attach = "a",
      clear_marked = "M",
      clear_target = "T",
      debug = "d",
      debug_marked = "D",
      expand = { "h", "l", "<2-LeftMouse>" },
      expand_all = "W",
      help = "?",
      jumpto = { "<CR>", "i", "j" },
      mark = "m",
      next_failed = "J",
      output = "o",
      prev_failed = "K",
      run = "r",
      run_marked = "R",
      short = "O",
      stop = "u",
      target = "t",
      watch = "w",
    },
    open = "botright vsplit | vertical resize 50",
  },
  watch = {
    enabled = true,
    symbol_queries = {},
  },
}
