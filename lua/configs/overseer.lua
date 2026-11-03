local overseer = require "overseer"

overseer.setup {
  dap = false,
  output = { use_terminal = false },
  component_aliases = {
    default = { "on_exit_set_status", "on_complete_notify", "user.log_buffer" },
  },
}

return require "moonshine.tasks"
