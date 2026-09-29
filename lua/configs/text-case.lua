local textcase = require "textcase"
textcase.setup {
  default_keymappings_enabled = false,
}
require("telescope").load_extension "textcase"
