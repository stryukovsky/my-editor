local function read_file(file_path)
  local f = io.open(file_path, "r")
  if f then
    local content = f:read "*all"
    f:close()
    return content
  end
  return ""
end

local chat_system_prompt = read_file(vim.fn.stdpath "config" .. "/ai/systemprompts/chat.txt")

require("codecompanion").setup {
  display = {
    diff = {
      enabled = false,
    },
  },
  interactions = {
    -- Change the default chat adapter
    chat = {
      opts = {
        system_prompt = function()
          return chat_system_prompt
        end,
      },
      adapter = "myadapter",
      keymaps = {
        close = {
          modes = { n = "<C-c>", i = "<C-c>" },
          opts = {},
        },
      },
    },
    inline = {
      adapter = "myadapter",
      keymaps = {
        accept_change = {
          modes = { n = "<leader>as" },
          description = "Accept the suggested change",
          callback = function() end,
        },
        reject_change = {
          modes = { n = "<leader>ar" },
          opts = { nowait = true },
          description = "Reject the suggested change",
          callback = function() end,
        },
      },
    },
    cmd = {
      adapter = "myadapter",
    },
  },
  adapters = {
    http = {
      myadapter = function()
        return require("codecompanion.adapters").extend("ollama", {
          name = "myadapter", -- Give this adapter a different name to differentiate it from the default ollama adapter
          opts = {
            vision = true,
            stream = true,
          },
          schema = {
            model = {
              default = "qwen3:0.6b",
            },
            num_ctx = {
              default = 16384,
            },
            think = {
              default = false,
            },
            keep_alive = {
              default = "30m",
            },
          },
        })
      end,
    },
  },
  opts = {
    log_level = "DEBUG", -- or "TRACE"
  },
}
