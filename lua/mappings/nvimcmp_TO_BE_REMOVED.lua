-- nvim-cmp
local cmp = require "cmp"
local luasnip = require "luasnip"

local nvim_cmp_next = function(fallback)
  if cmp.visible() then
    cmp.select_next_item()
  else
    fallback()
  end
end

local nvim_cmp_prev = function(fallback)
  if cmp.visible() then
    cmp.select_prev_item()
  else
    fallback()
  end
end

local nvim_cmp_next_with_snippet = function(fallback)
  if cmp.visible() then
    cmp.select_next_item()
  elseif luasnip.expand_or_jumpable() then
    luasnip.expand_or_jump()
  else
    fallback()
  end
end

local nvim_cmp_prev_with_snippet = function(fallback)
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
    ["<Tab>"] = cmp.mapping(nvim_cmp_next_with_snippet, { "i" }),
    ["<S-Tab>"] = cmp.mapping(nvim_cmp_prev_with_snippet, { "i" }),
    ["<A-Down>"] = cmp.mapping(nvim_cmp_next_with_snippet, { "i" }),
    ["<A-Up>"] = cmp.mapping(nvim_cmp_prev_with_snippet, { "i" }),
    ["<Down>"] = cmp.mapping(nvim_cmp_next, { "i" }),
    ["<Up>"] = cmp.mapping(nvim_cmp_prev, { "i" }),
  },
  view = {
    entries = {
      name = "custom",
      selection_order = "top_down",
      follow_cursor = false,
    },
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
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
    format = function(entry, vim_item)
      if vim.tbl_contains({ "path" }, entry.source.name) then
        local icon, hl_group = require("nvim-web-devicons").get_icon(entry.completion_item.label)
        if icon then
          vim_item.kind = icon
          vim_item.kind_hl_group = hl_group
          return vim_item
        end
      end
      return require("lspkind").cmp_format { with_text = false }(entry, vim_item)
    end,
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

