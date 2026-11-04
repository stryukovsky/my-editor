# Proposal

## Why

Global search finds text across files, but replacing selected occurrences requires jumping to each file and editing it manually. A dedicated picker would let the user review literal matches in Trouble and edit them individually or in one confirmed batch.

## What Changes

- Add a pretty Telescope picker for live, case-sensitive literal search with ripgrep.
- Open the results in a focused Trouble view on Enter.
- Add Normal-mode `r` to replace the occurrence under the cursor and `R` to replace all remaining results after a Yes/No confirmation.
- Apply replacements as undoable buffer edits for the user to save through Neovim.

## Capabilities

### New Capabilities

- `telescope-replacer` covers literal search, occurrence review, and individual or confirmed batch replacement.

### Modified Capabilities

## Impact

The feature uses the existing pretty picker, ripgrep, and Trouble source and mode integration. It adds a `:TelescopeReplacer` command.
