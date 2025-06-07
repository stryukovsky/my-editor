local textcase = require "textcase"
textcase.setup {
  default_keymappings_enabled = true,
  prefix = "gt",
}
require("telescope").load_extension "textcase"
