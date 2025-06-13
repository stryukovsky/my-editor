require("refactoring").setup {
  prompt_func_return_type = {
    go = true,
    java = true,
    c = true,
    typescript = true,

    cpp = false,
    h = false,
    hpp = false,
    cxx = false,
  },
  prompt_func_param_type = {
    go = true,
    java = true,

    cpp = false,
    c = false,
    h = false,
    hpp = false,
    cxx = false,
  },
  show_success_message = true,
}

require("telescope").load_extension "refactoring"
