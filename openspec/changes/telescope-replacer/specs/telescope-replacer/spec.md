# Telescope Replacer

## ADDED Requirements

### Requirement: Filter ripgrep results from Trouble

The live ripgrep handoff SHALL open a dedicated Trouble mode. Normal-mode
`f` SHALL open Telescope over the current result items. Enter SHALL filter
the Trouble view to the matching items or the explicit Telescope selection.
The Trouble results SHALL highlight matched spans in green before replacement.
Cancelling SHALL preserve the current results.

#### Scenario: Narrow a ripgrep result list
- **WHEN** the user searches in Telescope for one filename from the Trouble list and presses Enter
- **THEN** Trouble shows the matching results from that file

### Requirement: Preview replacement before editing

Normal-mode `r` in the ripgrep result view SHALL prompt for single-line
replacement text and open a separate, focused Trouble preview. The preview
SHALL show unchanged context once per occurrence, with removed text in red
and inserted text in green. Opening the preview or cancelling the prompt SHALL leave source
buffers unchanged.

#### Scenario: Preview repeated matches
- **WHEN** a retained line contains two matches and the user enters replacement text
- **THEN** the preview shows a separate proposed edit for each match

### Requirement: Apply individual or confirmed batch replacements

In the preview, Normal-mode `r` SHALL apply the focused occurrence.
Normal-mode `R` SHALL confirm the number of all remaining occurrences,
including folded rows, with No as the default. The actions SHALL use the
previewed replacement literally and accept an empty replacement as deletion.

#### Scenario: Apply one previewed occurrence
- **WHEN** the user presses `r` on a preview row
- **THEN** only that occurrence changes and the row is removed

#### Scenario: Confirm replacement of the remaining rows
- **WHEN** the user confirms `R` after applying one occurrence with `r`
- **THEN** the remaining occurrences are replaced and their rows are removed

### Requirement: Validate targets before editing

Replacements SHALL be undoable buffer edits. The replacer SHALL reject stale
or uneditable targets before applying any edits in a batch, preserve unrelated
unsaved changes, and refresh previews with the remaining byte ranges.

#### Scenario: Refuse a stale batch
- **WHEN** any target line changes after the preview and the user confirms `R`
- **THEN** the batch reports the stale target and leaves all targets untouched
