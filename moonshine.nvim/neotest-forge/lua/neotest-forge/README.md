# neotest-forge

Local Neotest adapter for Foundry projects (`foundry.toml`). Discovers Solidity
contracts and `test*`, `invariant*`, and `statefulFuzz*` functions in `*.t.sol`
files using the Solidity Tree-sitter parser.

Registered in `lua/configs/neotest.lua`. Uses the existing Neotest controls:

- `<leader>tt`: run the nearest test or contract.
- `<leader>tT`: run the current file.
- Neotest summary: browse tests and run a test, contract, file, or directory.
- Neotest output: Forge logs and failing execution traces (`-vvv`). Short output
  includes the failure reason, decoded logs, and fuzz counterexample.

Requires `forge` on PATH, with `forge test --json-file` support, and the Solidity
Tree-sitter parser. Forge runs from the closest Foundry root and uses the project's
normal configuration/profile. Extra Forge arguments can be passed through
`require("neotest").run.run { extra_args = { "--fuzz-runs", "10" } }`.

Discovery does not compile or run tests. Helper functions and `setUp` are excluded;
a failing `setUp` is reported against its contract's tests. Inherited tests without
a definition in the current file and DAP debugging are not supported.
