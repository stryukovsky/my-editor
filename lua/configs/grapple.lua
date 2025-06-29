---@diagnostic disable-next-line: missing-fields
require("grapple").setup {
  ---Default scope to use when managing Grapple tags
  ---For more information, please see the Scopes section
  ---@type string
  scope = "git",
}
require("telescope").load_extension "grapple"
