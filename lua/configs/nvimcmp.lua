local cmp = require "cmp"
local luasnip = require "luasnip"

cmp.setup {
  completion = { completeopt = "menu,menuone" },

  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert {
    ["<C-Down>"] = cmp.mapping.scroll_docs(-4),
    ["<C-Up>"] = cmp.mapping.scroll_docs(4),
    ["<C-k>"] = cmp.mapping.open_docs(),
    ["<C-Space>"] = cmp.mapping.complete(),
    -- ["<Tab>"] = cmp.mapping.select_next_item(),
    -- ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    ["<C-x>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    },
    -- ["<CR>"] = cmp.mapping {
    --   i = function(fallback)
    --     if cmp.visible() then
    --       if luasnip.expandable() and
    --         vim.print("Here")
    --         luasnip.expand()
    --       else
    --         cmp.confirm { behavior = cmp.ConfirmBehavior.Replace, select = true}
    --       end
    --     else
    --       fallback()
    --     end
    --   end,
    --   s = cmp.mapping.confirm { select = true },
    --   c = cmp.mapping.confirm { behavior = cmp.ConfirmBehavior.Replace, select = true },
    -- },

    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.locally_jumpable(1) then
        luasnip.jump(1)
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  },
  -- sources = cmp.config.sources({
  --   { name = "nvim_lsp" },
  --   { name = "luasnip", option = { show_autosnippets = true } }, -- For luasnip users.
  -- }, {
  --   { name = "buffer" },
  -- }),
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip", option = { show_autosnippets = true } },
    { name = "buffer" },
    { name = "nvim_lua" },
    { name = "path" },
  },
}

-- -- To use git you need to install the plugin petertriho/cmp-git and uncomment lines below
-- -- Set configuration for specific filetype.
-- --[[ cmp.setup.filetype('gitcommit', {
--     sources = cmp.config.sources({
--       { name = 'git' },
--     }, {
--       { name = 'buffer' },
--     })
--  })
--  require("cmp_git").setup() ]]
-- --

-- -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
-- cmp.setup.cmdline({ "/", "?" }, {
--   mapping = cmp.mapping.preset.cmdline(),
--   sources = {
--     { name = "buffer" },
--   },
-- })
--
-- -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
-- cmp.setup.cmdline(":", {
--   mapping = cmp.mapping.preset.cmdline(),
--   sources = cmp.config.sources({
--     { name = "path" },
--   }, {
--     { name = "cmdline" },
--   }),
--   matching = { disallow_symbol_nonprefix_matching = false },
-- })

-- -- Set up lspconfig.
-- local capabilities = require("cmp_nvim_lsp").default_capabilities()
-- -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
-- require("lspconfig")["<YOUR_LSP_SERVER>"].setup {
--   capabilities = capabilities,
-- }
