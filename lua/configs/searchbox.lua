require("searchbox").setup {
  defaults = {
    show_matches = true,
  },
  popup = {
    relative = "editor",
    position = {
      row = "50%",
      col = "50%",
    },
    size = 50,
    border = {
      style = "rounded",
      text = {
        top = " Search ",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
  },
  hooks = {
    after_mount = function(input)
      local function current_value()
        local line = vim.api.nvim_buf_get_lines(input.bufnr, 0, 1, false)[1] or ""
        return line:sub(input._.prompt:length() + 1)
      end
      -- for compat with other inputs of my neovim setup
      require("configs.input").bind_float_keys(input.bufnr, {
        -- Prompt-buffer <CR> in insert already submits; only add normal-mode CR.
        submit_modes = "n",
        submit = function()
          input.input_props.on_submit(current_value())
        end,
        cancel = function()
          input.input_props.on_close()
        end,
      })
    end,
    on_done = function(value)
      if value then
        require("configs.slashing").activate()
      end
    end,
  },
}
