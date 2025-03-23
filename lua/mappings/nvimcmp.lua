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
  },
}

-- cmp.setup.cmdline(":", {
--   mapping = cmp.mapping.preset.cmdline {
--     ["<Down>"] = cmp.mapping(nvim_cmp_next, { "c" }),
--     ["<Up>"] = cmp.mapping(nvim_cmp_prev, { "c" }),
--   },
-- })
