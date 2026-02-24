
local map = require("mappings.map")
-- Helper to set search register without moving cursor
local function highlight_current(is_visual)
    local pattern
    if is_visual then
        -- Get current visual selection
        local saved_reg = vim.fn.getreg('"')
        vim.cmd('noautocmd normal! "vy')
        pattern = "\\V" .. vim.fn.escape(vim.fn.getreg('"'), '\\/')
        vim.fn.setreg('"', saved_reg)
    else
        -- Get word under cursor with word boundaries
        pattern = "\\<" .. vim.fn.expand("<cword>") .. "\\>"
    end
    
    -- Set the search register and enable highlighting
    vim.fn.setreg('/', pattern)
    vim.opt.hlsearch = true
end

-- Map # to highlight word under cursor
map("n", "#", function() highlight_current(false) end, { desc = "Highlight word under cursor" })

-- Map # to highlight current visual selection
map("v", "#", function() highlight_current(true) end, { desc = "Highlight visual selection" })
