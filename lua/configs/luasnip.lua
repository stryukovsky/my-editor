-- vscode format
require("luasnip.loaders.from_vscode").lazy_load()
local config_dir = vim.fn.stdpath "config"
local snippets_dir = vim.fn.expand(config_dir .. "/snippets")

require("luasnip.loaders.from_vscode").lazy_load { paths = snippets_dir }

-- snipmate format
require("luasnip.loaders.from_snipmate").load()
require("luasnip.loaders.from_snipmate").lazy_load { paths = vim.g.snipmate_snippets_path or "" }

-- lua format
require("luasnip.loaders.from_lua").load()
require("luasnip.loaders.from_lua").lazy_load { paths = vim.g.lua_snippets_path or "" }
