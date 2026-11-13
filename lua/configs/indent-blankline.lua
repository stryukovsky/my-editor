local excluded_filetypes = vim.list_extend(
  vim.deepcopy(require("ibl.config").default_config.exclude.filetypes),
  require "moonshine.utils.technical_ui_filetypes"
)
table.insert(excluded_filetypes, "dashboard")

require("ibl").setup {
  exclude = { filetypes = excluded_filetypes },
}
