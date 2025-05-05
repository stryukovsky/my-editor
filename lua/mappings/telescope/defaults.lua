local function focus_preview(prompt_bufnr)
  local action_state = require "telescope.actions.state"
  local picker = action_state.get_current_picker(prompt_bufnr)
  local prompt_win = picker.prompt_win
  local previewer = picker.previewer
  local winid = previewer.state.winid
  local bufnr = previewer.state.bufnr
  vim.keymap.set("n", "<Tab>", function()
    vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", prompt_win))
  end, { buffer = bufnr })
  vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", winid))
  -- api.nvim_set_current_win(winid)
end

local actions = require "telescope.actions"

return {
  n = {
    ["<Esc>"] = function() end,
    -- ["q"] = actions.close,
    ["<Left>"] = actions.results_scrolling_left,
    ["<Right>"] = actions.results_scrolling_right,
    ["<A-Left>"] = actions.results_scrolling_left,
    ["<A-Right>"] = actions.results_scrolling_right,
  },
  i = {
    -- ["<Esc>"] = actions.close,
    ["<A-Left>"] = actions.results_scrolling_left,
    ["<A-Right>"] = actions.results_scrolling_right,
    ["<Tab>"] = focus_preview,
  },
}
