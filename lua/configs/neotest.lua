require("neotest").setup {
  adapters = {
    require "neotest-go",
    require "rustaceanvim.neotest",
    require "neotest-python",
    -- require "neotest-scala" {
    --   -- Command line arguments for runner
    --   -- Can also be a function to return dynamic values
    --   args = { "--no-color" },
    --   -- Runner to use. Will use bloop by default.
    --   -- Can be a function to return dynamic value.
    --   -- For backwards compatibility, it also tries to read the vim-test scala config.
    --   -- Possibly values bloop|sbt.
    --   runner = "sbt",
    --   -- Test framework to use. Will use utest by default.
    --   -- Can be a function to return dynamic value.
    --   -- Possibly values utest|munit|scalatest.
    --   framework = "scalatest",
    -- },
    require "neotest-jest" {
      jestCommand = "npm test --",
    },
  },
  benchmark = {
    enabled = true,
  },
  consumers = {},
  default_strategy = "integrated",
  diagnostic = {
    enabled = true,
    severity = 1,
  },
  discovery = {
    concurrent = 0,
    enabled = true,
  },
  floating = {
    border = "rounded",
    max_height = 0.6,
    max_width = 0.6,
    options = {},
  },
  highlights = {
    adapter_name = "NeotestAdapterName",
    border = "NeotestBorder",
    dir = "NeotestDir",
    expand_marker = "NeotestExpandMarker",
    failed = "NeotestFailed",
    file = "NeotestFile",
    focused = "NeotestFocused",
    indent = "NeotestIndent",
    marked = "NeotestMarked",
    namespace = "NeotestNamespace",
    passed = "NeotestPassed",
    running = "NeotestRunning",
    select_win = "NeotestWinSelect",
    skipped = "NeotestSkipped",
    target = "NeotestTarget",
    test = "NeotestTest",
    unknown = "NeotestUnknown",
    watching = "NeotestWatching",
  },
  icons = {
    child_indent = "│",
    child_prefix = "├",
    collapsed = "─",
    expanded = "╮",
    failed = "",
    final_child_indent = " ",
    final_child_prefix = "╰",
    non_collapsible = "─",
    notify = "",
    passed = "",
    running = "",
    running_animated = { "/", "|", "\\", "-", "/", "|", "\\", "-" },
    skipped = "",
    unknown = "",
    watching = "",
  },
  jump = {
    enabled = true,
  },
  log_level = 3,
  output = {
    enabled = true,
    open_on_run = "short",
  },
  output_panel = {
    enabled = true,
    open = "botright split | resize 15",
  },
  projects = {},
  quickfix = {
    enabled = true,
    open = false,
  },
  run = {
    enabled = true,
  },
  running = {
    concurrent = true,
  },
  state = {
    enabled = true,
  },
  status = {
    enabled = true,
    signs = true,
    virtual_text = false,
  },
  strategies = {
    integrated = {
      height = 40,
      width = 120,
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
      expand = { "<Left>", "<Right>", "<2-LeftMouse>" },
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
    enabled = false,
    symbol_queries = {},
  },
}
