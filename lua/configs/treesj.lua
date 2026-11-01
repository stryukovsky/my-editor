local treesj = require "treesj"
local lang_utils = require "treesj.langs.utils"
local solidity_args = lang_utils.set_preset_for_args {
  both = { shrink_node = { from = "(", to = ")" } },
}
local solidity_block = lang_utils.set_preset_for_statement {
  -- Solidity statements already contain their required semicolons.
  join = { force_insert = "" },
}
local langs = {
  solidity = {
    call_expression = solidity_args,
    function_definition = solidity_args,
    constructor_definition = solidity_args,
    return_type_definition = solidity_args,
    event_definition = solidity_args,
    error_declaration = solidity_args,
    tuple_expression = lang_utils.set_preset_for_args(),
    variable_declaration_tuple = lang_utils.set_preset_for_args(),
    inline_array_expression = lang_utils.set_preset_for_args(),
    call_argument = lang_utils.set_preset_for_dict {
      both = {
        last_separator = false,
        enable = function(node)
          return node:child(0):type() == "{"
        end,
      },
    },
    function_body = solidity_block,
    block_statement = solidity_block,
    struct_declaration = lang_utils.set_preset_for_statement {
      both = { shrink_node = { from = "{", to = "}" } },
      join = { force_insert = "" },
    },
    enum_declaration = lang_utils.set_preset_for_args {
      both = { shrink_node = { from = "{", to = "}" } },
      join = { space_in_brackets = true },
    },
  },
  scala = {
    object = lang_utils.set_preset_for_dict(),
    array = lang_utils.set_preset_for_list(),
    formal_parameters = lang_utils.set_preset_for_args(),
    parameters = lang_utils.set_preset_for_args(),
    arguments = lang_utils.set_preset_for_args(),
    statement_block = lang_utils.set_preset_for_statement {
      join = {
        no_insert_if = {
          "function_declaration",
          "try_statement",
          "if_statement",
        },
      },
    },
  },
}
treesj.setup { use_default_keymaps = false, langs = langs }
