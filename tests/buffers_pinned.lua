-- nvim --headless -u NONE -l tests/buffers_pinned.lua
vim.opt.rtp:append(vim.fn.getcwd() .. "/moonshine.nvim/buffers")
package.loaded.lualine = { refresh = function() end }
local buffers = require "moonshine.buffers"
vim.bo.buflisted = false
local a = vim.api.nvim_create_buf(true, false)
local b = vim.api.nvim_create_buf(true, false)
local c = vim.api.nvim_create_buf(true, false)
local d = vim.api.nvim_create_buf(true, false)
local function expect(expected)
  assert(vim.deep_equal(buffers.list(), expected), "Unexpected buffer order")
end
expect { a, b, c, d }
buffers.toggle_pin(c)
expect { c, a, b, d }
buffers.toggle_pin(b)
expect { c, b, a, d }
vim.api.nvim_set_current_buf(b)
buffers.move(-1)
expect { b, c, a, d }
buffers.move(1)
expect { c, b, a, d }
buffers.move(1)
expect { c, b, a, d } -- Pinned buffers cannot cross into the unpinned group.
vim.api.nvim_set_current_buf(a)
buffers.move(-1)
expect { c, b, a, d }
buffers.move(1)
expect { c, b, d, a }
buffers.toggle_pin(c)
expect { b, c, d, a }
vim.api.nvim_set_current_buf(b)
buffers.navigate(1)
assert(vim.api.nvim_get_current_buf() == c)
buffers.close_buffer()
assert(vim.api.nvim_get_current_buf() == b)
expect { b, d, a }
print "Pinned buffer order checks passed"
vim.cmd "qa!"
