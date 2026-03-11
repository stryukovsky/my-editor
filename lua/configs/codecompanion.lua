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
  prompt_library = {
    markdown = {
      dirs = { vim.fn.stdpath "config" .. "/ai/prompts/" },
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
      adapter = "myvllm",
      keymaps = {
        yank_code = {
          modes = { n = "<leader>y" },
          index = 8,
          callback = "keymaps.yank_code",
          description = "[Chat] Yank nearest code",
        },
        close = {
          modes = { n = "<C-c>", i = "<C-c>" },
          opts = {},
        },
      },
    },
    inline = {
      adapter = "myvllm",
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
      adapter = "myvllm",
    },
  },
  adapters = {
    http = {
      myvllm = function()
        return require("codecompanion.adapters").extend("openai", {
          name = "myvllm", -- Unique name for your adapter
          formatted_name = "VLLM | Use `<leader>y` to yank code",
          -- api_key = "sk-no-key-required", -- vLLM does not require an API key

          url = "http://localhost:18993/v1/chat/completions",
          schema = {
            model = {
              default = "Qwen/Qwen2.5-Coder-7B-Instruct-AWQ", -- Must match your vllm model name
            },
          },
        })
      end,
      mylocalollama = function()
        return require("codecompanion.adapters").extend("ollama", {
          name = "mylocalollama", -- Give this adapter a different name to differentiate it from the default ollama adapter
          opts = {
            vision = true,
            stream = true,
          },
          schema = {
            model = {
              default = "qwen2.5-coder:14b",
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
