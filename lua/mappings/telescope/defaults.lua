local function focus_preview(prompt_bufnr)
  local action_state = require "telescope.actions.state"
  local picker = action_state.get_current_picker(prompt_bufnr)
  if picker.previewer then
    local prompt_win = picker.prompt_win
    local previewer = picker.previewer
    local winid = previewer.state.winid
    local bufnr = previewer.state.bufnr
    vim.keymap.set("n", "<Tab>", function()
      vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", prompt_win))
    end, { buffer = bufnr })

    vim.keymap.set({"n", "i", "v", "x"}, "<A-w>", function() end, { buffer = bufnr })
    vim.keymap.set({"n", "i", "v", "x"}, "<A-a>", function() end, { buffer = bufnr })
    vim.keymap.set({"n", "i", "v", "x"}, "<A-s>", function() end, { buffer = bufnr })
    vim.keymap.set({"n", "i", "v", "x"}, "<A-d>", function() end, { buffer = bufnr })

    vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", winid))
  end
end
local function dummy() end
local actions = require "telescope.actions"
local open_with_trouble = require("trouble.sources.telescope").open
return {
  n = {
    -- ["<Esc>"] = function() end,
    -- ["q"] = actions.close,
    -- ["<Left>"] = actions.results_scrolling_left,
    ["<C-h>"] = actions.results_scrolling_left,
    -- ["<Right>"] = actions.results_scrolling_right,
    ["<C-l>"] = actions.results_scrolling_right,
    -- ["<Down>"] = actions.results_scrolling_down,
    ["<C-j>"] = actions.results_scrolling_down,
    -- ["<Up>"] = actions.results_scrolling_up,
    ["<C-k>"] = actions.results_scrolling_up,
    ["<A-t>"] = open_with_trouble,
    ["<A-a>"] = dummy,
    ["<A-s>"] = dummy,
    ["<A-d>"] = dummy,
    ["<A-w>"] = dummy,
    ["<Tab>"] = focus_preview,
    ["<A-q>"] = dummy,
  },
  i = {
    -- ["<Left>"] = actions.results_scrolling_left,
    ["<C-h>"] = actions.results_scrolling_left,
    -- ["<Right>"] = actions.results_scrolling_right,
    ["<C-l>"] = actions.results_scrolling_right,
    -- ["<Down>"] = actions.results_scrolling_down,
    ["<C-j>"] = actions.results_scrolling_down,
    -- ["<Up>"] = actions.results_scrolling_up,
    ["<C-k>"] = actions.results_scrolling_up,
    ["<A-t>"] = open_with_trouble,
    ["<A-a>"] = dummy,
    ["<A-s>"] = dummy,
    ["<A-d>"] = dummy,
    ["<A-w>"] = dummy,
    ["<A-q>"] = dummy,
  },
}
