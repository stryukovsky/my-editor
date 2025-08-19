require("codecompanion").setup {
  strategies = {
    -- Change the default chat adapter
    chat = {
      adapter = "ollama",
      model = "qwen2.5-coder:14b",
      keymaps = {
        close = {
          modes = { n = "<C-c>", i = "<C-c>" },
          opts = {},
        },
      },
    },
    inline = {
      adapter = "ollama",
      model = "qwen2.5-coder:7b",
      keymaps = {
        accept_change = {
          modes = { n = "ga" },
          description = "Accept the suggested change",
          callback = function() end,
        },
        reject_change = {
          modes = { n = "gr" },
          opts = { nowait = true },
          description = "Reject the suggested change",
          callback = function() end,
        },
      },
    },
    cmd = {
      adapter = "ollama",
      model = "qwen2.5-coder:7b",
    },
  },
  opts = {
    log_level = "DEBUG", -- or "TRACE"
  },
}
