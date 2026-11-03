# Proposal

## Why

The active configuration runs Neovim 0.12.6 and already uses native completion and LSP startup, but retains plugins for several overlapping editing features. Prefer native behavior where it reduces maintenance while making feature losses explicit.

## What Changes

- Propose a conservative first implementation: native line commenting, retaining Solidity and shell comment syntax and the existing TODO insertion command.
- Record the complete plugin-to-native options table in design.md, with conditional migrations and features best retained.
- Preserve current native completion, snippet navigation, Tree-sitter folding, and LSP startup.
- Treat blockwise commenting as outside the first migration; retain Comment.nvim until its required behavior is explicitly resolved during implementation review. Do not silently remove its blockwise commands.
- Optional table rows are alternatives for separate changes, not implied implementation scope.

## Capabilities

### New Capabilities

- `comment-editing`: Line comment toggling and TODO insertion across configured languages and keyboard layouts.

### Modified Capabilities

None. The project currently has no main specs.

## Impact

First implementation would touch lua/configs/comment.lua, lua/configs/init.lua, lua/mappings/todo.lua, lua/plugins/core.lua, and documentation. Mapping changes must use mappings.map for RU/EN support. No runtime configuration is changed by this proposal. Existing file-tree proposals remain independent.
