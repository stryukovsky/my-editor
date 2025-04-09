require("neotest").setup {
  -- your neotest config here
  adapters = {
    require "neotest-go",
    require "rustaceanvim.neotest",
    require "neotest-python",
  },
}
