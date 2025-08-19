require("codecompanion").setup {
  strategies = {
    -- Change the default chat adapter
    chat = {
      adapter = "ollama",
      model = "qwen2.5-coder:14b",
    },
    inline = {
      adapter = "ollama",
      model = "qwen2.5-coder:7b",
      keymaps = {
        accept_change = {
          modes = { n = "ga" },
          description = "Accept the suggested change",
        },
        reject_change = {
          modes = { n = "gr" },
          opts = { nowait = true },
          description = "Reject the suggested change",
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
