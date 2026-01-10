local source_icons = {
  minuet = "󱗻",
  orgmode = "",
  otter = "󰼁",
  nvim_lsp = "",
  lsp = "",
  buffer = "",
  luasnip = "",
  snippets = "",
  path = "",
  git = "",
  tags = "",
  cmdline = "󰘳",
  latex_symbols = "",
  cmp_nvim_r = "󰟔",
  codeium = "󰩂",
  -- FALLBACK
  fallback = "󰜚",
}

local is_ollama_installed = require "utils.is_ollama_installed"
local sources = { "lsp", "path", "snippets", "buffer" }
if not is_ollama_installed() then
  sources = { "lsp", "path", "snippets", "buffer" }
end

---@module 'blink.cmp'
---@type blink.cmp.Config
require("blink-cmp").setup {
  keymap = {
    preset = "none",
    ["<cr>"] = { "accept", "fallback" },
    ["<Up>"] = { "select_prev", "fallback" },
    ["<Down>"] = { "select_next", "fallback" },
    ["<A-Down>"] = { "scroll_documentation_down", "fallback" },
    ["<A-Up>"] = { "scroll_documentation_up", "fallback" },
    ["<C-j>"] = { "select_next", "fallback" },
    ["<C-k>"] = { "select_prev", "fallback" },
    ["<C-g>"] = require("minuet").make_blink_map(),
  },

  appearance = {
    use_nvim_cmp_as_default = true,
    nerd_font_variant = "mono",
    kind_icons = source_icons,
  },

  cmdline = {
    keymap = {
      ["<cr>"] = { "accept", "fallback" },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<A-Down>"] = { "scroll_documentation_down", "fallback" },
      ["<A-Up>"] = { "scroll_documentation_up", "fallback" },
      ["<C-j>"] = { "select_next", "fallback" },
      ["<C-k>"] = { "select_prev", "fallback" },
      ["<Tab>"] = { "show" },
    },
  },
  sources = {
    default = sources,
    providers = {
      minuet = {
        name = "minuet",
        module = "minuet.blink",
        async = true,
        -- Should match minuet.config.request_timeout * 1000,
        -- since minuet.config.request_timeout is in seconds
        timeout_ms = 19000,
        score_offset = -50, -- Gives minuet lower priority among suggestions
      },
    },
  },

  -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
  -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
  -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
  --
  -- See the fuzzy documentation for more information
  fuzzy = { implementation = "prefer_rust_with_warning" },

  completion = {
    documentation = { auto_show = true, window = { border = "single" } },
    trigger = { prefetch_on_insert = true },
    menu = {
      border = "single",
      draw = {
        columns = {
          { "label", "label_description", gap = 1 },
          { "kind_icon", "kind", gap = 1 },
          { "source_icon" },
        },
        components = {
          source_icon = {
            -- don't truncate source_icon
            ellipsis = false,
            text = function(ctx)
              return source_icons[ctx.source_name:lower()] or source_icons.fallback
            end,
            highlight = "BlinkCmpSource",
          },
          kind_icon = {
            ellipsis = false,
            text = function(ctx)
              local icon = ctx.kind_icon
              if vim.tbl_contains({ "Path" }, ctx.source_name) then
                local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                if dev_icon then
                  icon = dev_icon
                end
              else
                icon = require("lspkind").symbolic(ctx.kind, {
                  mode = "symbol",
                })
              end

              return icon .. ctx.icon_gap
            end,

            -- Optionally, use the highlight groups from nvim-web-devicons
            -- You can also add the same function for `kind.highlight` if you want to
            -- keep the highlight groups in sync with the icons.
            highlight = function(ctx)
              local hl = ctx.kind_hl
              if vim.tbl_contains({ "Path" }, ctx.source_name) then
                local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                if dev_icon then
                  hl = dev_hl
                end
              end
              return hl
            end,
          },
        },
      },
    },
  },
}
