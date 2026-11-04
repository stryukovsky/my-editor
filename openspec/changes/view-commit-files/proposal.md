# Proposal

## Why

A commit can identify which files to revisit while the working tree holds the versions the user wants to read.

## What Changes

- Add **View affected files (v)** to the pretty commit action menu and expose it as a direct Normal-mode shortcut.
- List the selected commit's affected paths that can still be opened in the current working tree. Choosing a Trouble entry opens its regular file buffer.

## Capabilities

### Modified Capabilities

- `git-picker-actions` gains a working-tree file view for the selected commit.

## Impact

The pretty commit picker uses the existing Git helper and Trouble integration.
