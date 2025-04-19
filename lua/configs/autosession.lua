return {
  close_unsupported_windows = true, -- Close windows that aren't backed by normal file before autosaving a session
  use_git_branch = true, -- Include git branch name in session name
  suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
  -- log_level = 'debug',
  pre_save_cmds = {
    "silent! tabonly 1",
  },
  pre_restore_cmds = {
    function()
      -- Restore nvim-tree after a session is restored
      local nvim_tree_api = require "nvim-tree.api"
      nvim_tree_api.tree.open()
      nvim_tree_api.tree.change_root(vim.fn.getcwd())
      nvim_tree_api.tree.reload()
    end,
  },
}
