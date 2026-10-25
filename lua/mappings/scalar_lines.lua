local map = require "mappings.map"
local scalar_lines = require "scalar_lines"

map(
  { "n", "x" },
  "<leader>dotc",
  scalar_lines.cancel,
  { desc = "Scalar lines: cancel" }
)

map(
  { "n", "x" },
  "<leader>dots",
  scalar_lines.dot,
  { desc = "Scalar lines: start / finish source / apply" }
)

map(
  { "n", "x" },
  "<leader>dotx",
  scalar_lines.remove,
  { desc = "Scalar lines: remove current line selection" }
)
