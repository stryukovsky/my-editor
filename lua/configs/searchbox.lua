require("searchbox").setup {
  defaults = {
    show_matches = true,
  },
  popup = {
    relative = "editor",
    position = {
      row = "50%",
      col = "50%",
    },
    size = 50,
    border = {
      style = "rounded",
      text = {
        top = " Search ",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
  },
  hooks = {
    on_done = function(value)
      if value then
        require("hlslens").start()
      end
    end,
  },
}
