local cmp = require "cmp"
local luasnip = require "luasnip"
local function is_cursor_on_word()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1  -- convert to 1-based index

    -- Get the character under cursor and the one before it
    local char_at = line:sub(col, col)
    local char_before = col > 1 and line:sub(col - 1, col - 1) or ''

    -- Check if either character is word-like
    local is_word_char = char_at:match('[%w_]')
    local is_word_char_before = char_before:match('[%w_]')

    -- Cursor is on a word if:
    -- 1. Current character is word-like, OR
    -- 2. Previous character is word-like (beginning of word)
    -- return is_word_char ~= nil or is_word_char_before ~= nil
    return is_word_char ~= nil and not is_word_char_before
end
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
    -- ["<C-k>"] = cmp.mapping.open_docs(),
    ["<C-Space>"] = function()
      if cmp.visible() then
        cmp.abort()
      else
        cmp.complete()
      end
    end,
    ["<C-S>"] = cmp.mapping(function(fallback)
      if luasnip.expandable() then
        luasnip.expand {}
      else
        fallback()
      end
    end),
    ["<C-x>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        if is_cursor_on_word() then
          cmp.confirm { select = true, behavior = cmp.ConfirmBehavior.Replace }
        else
          cmp.confirm {
            behavior = cmp.ConfirmBehavior.Insert,
            select = true,
          }
        end
      else
        fallback()
      end
    end),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        if #cmp.get_entries() == 1 then
          cmp.confirm { select = true }
        else
          cmp.select_next_item()
        end
      elseif luasnip.locally_jumpable(1) then
        luasnip.jump(1)
      elseif is_cursor_on_word() then
        cmp.complete()
        if #cmp.get_entries() == 1 then
          cmp.confirm { select = true }
        end
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { "i", "s" }),
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip", option = { show_autosnippets = true } },
    { name = "buffer" },
    { name = "nvim_lua" },
    { name = "path" },
    { name = "nvim_lsp_signature_help" },
  },
}
