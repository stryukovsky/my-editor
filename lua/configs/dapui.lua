require("dapui").setup {
  controls = {
    element = "breakpoints",
    enabled = true,
    icons = {
      disconnect = "",
      pause = "",
      play = "",
      run_last = "",
      step_back = "",
      step_into = "",
      step_out = "",
      step_over = "",
      terminate = "",
    },
  },
  element_mappings = {},
  expand_lines = true,
  floating = {
    max_width = 140,
    max_height = 80,
    border = "rounded",
    mappings = {
      close = { "q", "<Esc>" },
    },
  },
  force_buffers = true,
  icons = {
    collapsed = "",
    current_frame = "",
    expanded = "",
  },
  layouts = {
    {
      elements = {
        {
          id = "scopes",
          size = 0.40,
        },
        {
          id = "stacks",
          size = 0.35,
        },
        {
          id = "breakpoints",
          size = 0.25,
        },
        -- {
        --   id = "watches",
        --   size = 0.25,
        --   enabled = false
        -- },
      },
      position = "left",
      size = 40,
    },
    {
      elements = {
        {
          id = "repl",
          size = 1,
        },
        {
          id = "console",
          size = 0.01,
        },
      },
      position = "bottom",
      size = 15,
    },
  },
  mappings = {
    edit = "e",
    expand = { "<CR>", "<2-LeftMouse>", "l", "h" },
    open = {"<CR>", "o"},
    remove = "d",
    repl = "r",
    toggle = "<leader>t",
  },
  render = {
    indent = 1,
    max_value_lines = 100,
  },
}
