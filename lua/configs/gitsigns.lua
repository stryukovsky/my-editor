require("gitsigns").setup {
  word_diff = false,
  current_line_blame = true,
  current_line_blame_opts = {
    delay = 400,
    use_focus = true,
    virt_text = true,
    virt_text_pos = "right_align",
    virt_text_priority = 100,
  },
}
