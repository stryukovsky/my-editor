local llm = require "minuet"

local function is_ollama_installed()
  return pcall(function()
    vim.system({ "ollama" }):wait()
  end)
end

if is_ollama_installed() then
  llm.setup {
    provider = "openai_fim_compatible",
    -- I recommend beginning with a small context window size and incrementally
    -- expanding it, depending on your local computing power. A context window
    -- of 512, serves as an good starting point to estimate your computing
    -- power. Once you have a reliable estimate of your local computing power,
    -- you should adjust the context window to a larger value.
    context_window = 256,
    throttle = 1000, -- only send the request every x milliseconds, use 0 to disable throttle.
    -- debounce the request in x milliseconds, set to 0 to disable debounce
    debounce = 400,
    provider_options = {
      openai_fim_compatible = {
        -- For Windows users, TERM may not be present in environment variables.
        -- Consider using APPDATA instead.
        api_key = function()
          return "sk-xxxx"
        end,
        name = "Ollama",
        end_point = "http://localhost:11434/v1/completions",
        model = "deepseek-coder-v2:lite",
        optional = {
          max_tokens = 56,
          top_p = 0.9,
        },
      },
    },
    notify = "warn", -- debug or verbose if needed
    n_completions = 3,
    blink = {
      enable_auto_complete = true,
    },
  }
end
