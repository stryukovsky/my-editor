local llm = require "llm"

local function is_ollama_installed()
  return pcall(function()
    vim.system({ "ollama" }):wait()
  end)
end

if is_ollama_installed() then
  llm.setup {
    api_token = nil, -- cf Install paragraph
    model = "codellama:7b", -- the model ID, behavior depends on backend
    backend = "ollama", -- backend ID, "huggingface" | "ollama" | "openai" | "tgi"
    url = "http://localhost:11434",
    -- parameters that are added to the request body, values are arbitrary, you can set any field:value pair here it will be passed as is to the backend
    request_body = {
      parameters = {
        max_new_tokens = 20,
        temperature = 0.2,
        top_p = 0.95,
      },
    },
    -- set this if the model supports fill in the middle

    tokens_to_clear = { "<EOT>" },
    fim = {
      enabled = false,
      prefix = "<PRE> ",
      middle = " <MID>",
      suffix = " <SUF>",
    },
    debounce_ms = 150,
    accept_keymap = "<C-s>",
    dismiss_keymap = "<C-space>",
    tls_skip_verify_insecure = false,
    -- llm-ls configuration, cf llm-ls section
    lsp = {
      bin_path = vim.api.nvim_call_function("stdpath", { "data" }) .. "/mason/bin/llm-ls",
      -- host = nil,
      -- port = nil,
      -- cmd_env = nil, -- or { LLM_LOG_LEVEL = "DEBUG" } to set the log level of llm-ls
      -- version = "0.5.3",
    },
    tokenizer = nil, -- cf Tokenizer paragraph
    context_window = 1024, -- max number of tokens for the context window
    enable_suggestions_on_startup = true,
    enable_suggestions_on_files = "*", -- pattern matching syntax to enable suggestions on specific files, either a string or a list of strings
    disable_url_path_completion = false, -- cf Backend
  }
end
