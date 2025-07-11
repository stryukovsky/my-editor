local function local_llm_streaming_handler(chunk, ctx, F)
  if not chunk then
    return ctx.assistant_output
  end
  local tail = chunk:sub(-1, -1)
  if tail:sub(1, 1) ~= "}" then
    ctx.line = ctx.line .. chunk
  else
    ctx.line = ctx.line .. chunk
    local status, data = pcall(vim.fn.json_decode, ctx.line)
    if not status or not data.message.content then
      return ctx.assistant_output
    end
    ctx.assistant_output = ctx.assistant_output .. data.message.content
    F.WriteContent(ctx.bufnr, ctx.winid, data.message.content)
    ctx.line = ""
  end
  return ctx.assistant_output
end

local function local_llm_parse_handler(chunk)
  local assistant_output = chunk.message.content
  return assistant_output
end

local keys_close = { "<esc>", "q", "Q", "<A-q>", "<A-a>", "<A-s>", "<A-w>", "<A-d>" }
local keys_accept = { "<C-s>", "<leader>y", "<cr>" }
local keys_reject = { "<C-x>", "<C-c>" }

local function is_ollama_installed()
  return pcall(function()
    vim.system({ "ollama" }):wait()
  end)
end

if is_ollama_installed() then
  vim.env.LLM_KEY = ""
  local llm = require "llm"
  local tools = require "llm.tools"
  local model = "qwen2.5-coder:7b"
  vim.print("Ollama installed, setup using " .. model)
  llm.setup {
    url = "http://localhost:11434/api/chat",
    api_type = "ollama",
    temperature = 0.3,
    top_p = 0.7,
    model = model,
    streaming_handler = local_llm_streaming_handler,
    app_handler = {
      Completion = {
        style = "virtual_text",
        handler = tools.completion_handler,
        opts = {
          -------------------------------------------------
          ---                   ollama
          -------------------------------------------------
          url = "http://localhost:11434/v1/completions",
          api_type = "ollama",

          model = model,
          n_completions = 1,
          context_window = 242,
          max_tokens = 4,

          -- A mapping of filetype to true or false, to enable completion.
          filetypes = {
            sh = true,
            rust = true, -- Note. To prevent this from happening, use ! as prefix before the command!!
            vimrc = true,
            config = true,
            jsonnet = true,
            html = true,
            javascript = true,
            python = true,
            bash = true,
            julia = true,
            typescript = true,
            scala = true,
            go = true,
            yaml = true,
            json = true,
            kotlin = true,
            java = true,
            lua = true,
            php = true,
          },

          -- Whether to enable completion of not for filetypes not specifically listed above.
          default_filetype_enabled = false,

          auto_trigger = true,

          -- just trigger by { "@", ".", "(", "[", ":", " " } for `style = "nvim-cmp"`
          only_trigger_by_keywords = false,

          style = "virtual_text", -- nvim-cmp or blink.cmp

          timeout = 10, -- max request time

          -- only send the request every x milliseconds, use 0 to disable throttle.
          throttle = 1000,
          -- debounce the request in x milliseconds, set to 0 to disable debounce
          debounce = 400,

          --------------------------------
          ---   just for virtual_text
          --------------------------------
          keymap = {
            virtual_text = {
              accept = {
                mode = "i",
                keys = "<C-s>",
              },
            },
          },
        },
      },
      WordTranslate = {
        handler = tools.flexi_handler,
        prompt = "Translate the following text to Russian, please only return the translation",
        opts = {
          parse_handler = local_llm_parse_handler,
          exit_on_move = true,
          enter_flexible_window = false,
        },
      },
      Ask = {
        handler = tools.disposable_ask_handler,
        opts = {
          position = {
            row = 2,
            col = 0,
          },
          title = " Ask ",
          inline_assistant = true,

          -- Whether to use the current buffer as context without selecting any text (the tool is called in normal mode)
          enable_buffer_context = true,
          language = "English",
          -- url = "http://localhost:11434/api/chat",
          -- api_type = "ollama",
          -- parse_handler = local_llm_parse_handler,
          exit_on_move = true,
          enter_flexible_window = false,
          -- display diff
          display = {
            mapping = {
              mode = "n",
              keys = { "<cr>" },
            },
            action = nil,
          },
          accept = {
            mapping = {
              mode = "n",
              keys = keys_accept,
            },
            action = nil,
          },
          reject = {
            mapping = {
              mode = "n",
              keys = keys_reject,
            },
            action = nil,
          },
          close = {
            mapping = {
              mode = "n",
              keys = keys_close,
            },
            action = nil,
          },
        },
      },
      TestCode = {
        handler = tools.side_by_side_handler,
        prompt = [[ Write some test cases for the following code, only return the test cases.
Give the code content directly, do not use code blocks or other tags to wrap it. ]],
        opts = {
          right = {
            title = " Test Cases ",
          },
          accept = {
            mapping = {
              mode = "n",
              keys = keys_accept,
            },
            action = nil,
          },
          reject = {
            mapping = {
              mode = "n",
              keys = keys_reject,
            },
            action = nil,
          },
          close = {
            mapping = {
              mode = "n",
              keys = keys_close,
            },
            action = nil,
          },
        },
      },
      DocString = {
        prompt = [[ You are an AI programming assistant. You need to write a really good docstring that follows a best practice for the given language.

Your core tasks include:
- parameter and return types (if applicable).
- any errors that might be raised or returned, depending on the language.

You must:
- Place the generated docstring before the start of the code.
- Follow the format of examples carefully if the examples are provided.
- Use Markdown formatting in your answers.
- Include the programming language name at the start of the Markdown code blocks.]],
        handler = tools.action_handler,
        opts = {
          only_display_diff = true,
          templates = {
            lua = [[- For the Lua language, you should use the LDoc style.
- Start all comment lines with "---".
]],
            go = "use godoc format for documentation",
          },
          accept = {
            mapping = {
              mode = "n",
              keys = keys_accept,
            },
            action = nil,
          },
          reject = {
            mapping = {
              mode = "n",
              keys = keys_reject,
            },
            action = nil,
          },
          close = {
            mapping = {
              mode = "n",
              keys = keys_close,
            },
            action = nil,
          },
        },
      },
    },
  -- stylua: ignore
  keys = {
    -- The keyboard mapping for the input window.
    ["Input:Submit"]      = { mode = "n", key = "<cr>" },
    ["Input:Cancel"]      = { mode = {"n", "i"}, key = "<C-c>" },
    ["Input:Resend"]      = { mode = {"n", "i"}, key = "<C-r>" },

    -- only works when "save_session = true"
    ["Input:HistoryNext"] = { mode = {"n", "i"}, key = "<C-j>" },
    ["Input:HistoryPrev"] = { mode = {"n", "i"}, key = "<C-k>" },

    -- The keyboard mapping for the output window in "split" style.
    ["Output:Ask"]        = { mode = "n", key = "i" },
    ["Output:Cancel"]     = { mode = "n", key = "<C-c>" },
    ["Output:Resend"]     = { mode = "n", key = "<C-r>" },

    -- The keyboard mapping for the output and input windows in "float" style.
    -- ["Session:Toggle"]    = { mode = "n", key = "<A-q>" },
    -- ["Session:Close"]     = { mode = "n", key = {"<esc>", "Q"} },

    -- Scroll
    ["PageUp"]            = { mode = {"i","n"}, key = "<A-Up>" },
    ["PageDown"]          = { mode = {"i","n"}, key = "<A-Down>" },
    -- ["HalfPageUp"]        = { mode = {"i","n"}, key = "<C-u>" },
    -- ["HalfPageDown"]      = { mode = {"i","n"}, key = "<C-d>" },
    ["JumpToTop"]         = { mode = "n", key = "gg" },
    ["JumpToBottom"]      = { mode = "n", key = "G" },
  },
  }
end
