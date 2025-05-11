-- nvim-cmp
local cmp = require "cmp"
local luasnip = require "luasnip"

--
local nvim_cmp_next = function(fallback)
  if cmp.visible() then
    cmp.select_next_item()
  elseif luasnip.expand_or_jumpable() then
    luasnip.expand_or_jump()
  else
    fallback()
  end
end

local nvim_cmp_prev = function(fallback)
  if cmp.visible() then
    cmp.select_prev_item()
  elseif luasnip.jumpable(-1) then
    luasnip.jump(-1)
  else
    fallback()
  end
end

cmp.setup.global {
  mapping = cmp.mapping.preset.insert {
    ["<Down>"] = cmp.mapping(nvim_cmp_next, { "i" }),
    ["<Up>"] = cmp.mapping(nvim_cmp_prev, { "i" }),
    ["<A-Down>"] = cmp.mapping(nvim_cmp_next, { "i" }),
    ["<A-Up>"] = cmp.mapping(nvim_cmp_prev, { "i" }),
  },
  view = {
    entries = {
      name = "custom",
      selection_order = "near_cursor",
      follow_cursor = true,
    },
  },
  sources = cmp.config.sources {
    {
      name = "nvim_lsp",
      group_index = 1,
    },
    {
      name = "treesitter",
      keyword_length = 4,
      group_index = 2,
    },
    {
      name = "luasnip",
      group_index = 3,
      option = { use_show_condition = true },
      entry_filter = function()
        local context = require "cmp.config.context"
        return not context.in_treesitter_capture "string" and not context.in_syntax_group "String"
      end,
    },
    {
      name = "path",
      keyword_length = 4,
      group_index = 4,
    },
    {
      name = "buffer",
      keyword_length = 3,
      group_index = 5,
      option = {
        get_bufnrs = function()
          local bufs = {}
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            bufs[vim.api.nvim_win_get_buf(win)] = true
          end
          return vim.tbl_keys(bufs)
        end,
      },
    },
  },
  ---@diagnostic disable-next-line: missing-fields
  formatting = {
    expandable_indicator = true,
  },
  sorting = {
    priority_weight = 1,
    comparators = {
      cmp.config.compare.score,
      cmp.config.compare.offset,
      cmp.config.compare.length,
      cmp.config.compare.exact,
      cmp.config.compare.recently_used,
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.order,
    },
  },
}

-- cmp.setup.cmdline(":", {
--   mapping = cmp.mapping.preset.cmdline {
--     ["<Down>"] = cmp.mapping(nvim_cmp_next, { "c" }),
--     ["<Up>"] = cmp.mapping(nvim_cmp_prev, { "c" }),
--   },
-- })
