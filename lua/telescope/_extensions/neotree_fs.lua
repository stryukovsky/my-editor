return require("telescope").register_extension {
  exports = {
    neotree_fs = require "telescope_neotree_fs",
  },
}
