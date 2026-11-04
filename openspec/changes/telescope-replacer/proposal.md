## Why

Ripgrep results already open in Trouble. Filtering and replacing from that list
lets the user refine an existing search and inspect the proposed edits before
changing buffers.

## What Changes

- Add `f` to ripgrep results in Trouble. It opens Telescope over the current
  results and applies the matching or explicitly selected subset on Enter.
- Add `r` to ripgrep results. It asks for replacement text and opens a separate
  Trouble view with inline red matches and green replacement text.
- In the preview, `r` applies one occurrence and `R` applies all remaining
  occurrences after confirmation.

## Capabilities

### New Capabilities

- `telescope-replacer` covers filtering ripgrep results, previewing changes,
  and applying individual or confirmed batch replacements.

## Impact

The existing live ripgrep picker hands off to a dedicated Trouble mode.
Replacements are undoable edits in Neovim buffers that can be saved normally.
