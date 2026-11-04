# Telescope Replacer

## Purpose

Review exact text occurrences across files and replace individual matches or a confirmed batch from Trouble.

## ADDED Requirements

### Requirement: Live literal search

`:TelescopeReplacer` SHALL open a pretty Telescope picker that uses ripgrep to search the working directory captured at launch. The search SHALL be case-sensitive, treat the query as literal text, and show one result per occurrence with its file, line, column, and context. An empty query SHALL have no results.

#### Scenario: Search for literal punctuation
- **WHEN** the query is `a.b` and the search contains `a.b a.b A.B axb`
- **THEN** the picker shows the two lowercase literal occurrences as separate results

### Requirement: Review the result set in Trouble

Enter in Normal or Insert mode SHALL open the completed result set for the current query in a focused, navigable Trouble view. The results SHALL retain their source locations. Enter with no results SHALL leave the picker open. If the result set exceeds the review limit, the picker SHALL ask the user to narrow the search before transferring it.

#### Scenario: Navigate search results
- **WHEN** the user presses Enter on a completed search with matches
- **THEN** Trouble opens focused on the selected match and the user can navigate and jump to the other occurrences

### Requirement: Replace the current occurrence

Normal-mode `r` on a Trouble match SHALL prompt for replacement text and apply it literally to that occurrence. An empty replacement SHALL delete the occurrence. Cancelling SHALL preserve the result set and source text. The action SHALL have no effect on a group row.

#### Scenario: Replace only the focused match
- **WHEN** a line contains two matches and the user presses `r` on the second and enters `$1`
- **THEN** only the second occurrence changes to the literal text `$1` and its row is removed

### Requirement: Confirm replacement of all remaining occurrences

Normal-mode `R` SHALL prompt for replacement text and show a Yes/No confirmation with the number of remaining occurrences in the review session, including folded rows. No SHALL be the default. Changes SHALL begin only after an affirmative answer.

#### Scenario: Decline the batch
- **WHEN** the user enters replacement text and answers No or dismisses the confirmation
- **THEN** the action leaves buffers and results intact

#### Scenario: Replace across files
- **WHEN** the user confirms a batch after already replacing one occurrence with `r`
- **THEN** all remaining occurrences in the review are replaced and their rows are removed

### Requirement: Validate targets before editing

Replacements SHALL be undoable Neovim buffer edits that the user can save normally. The replacer SHALL verify pending targets against current buffer contents before editing. If a target is stale or cannot be edited, the action SHALL report it, and a batch with a failed preflight SHALL leave every target untouched. Successful edits SHALL keep remaining rows accurate.

#### Scenario: Preserve unrelated unsaved edits
- **WHEN** a loaded target buffer contains an unsaved change outside the lines being replaced and those target lines remain valid
- **THEN** the replacement preserves the unrelated change and leaves the buffer available for normal save and undo

#### Scenario: Refuse a stale batch
- **WHEN** a target line has changed since the search and the user confirms `R`
- **THEN** the batch reports the stale target and makes no replacement edits

#### Scenario: Update the byte column after replacement
- **WHEN** the user replaces the first of two matches on the same line with text of a different byte length
- **THEN** the second row still navigates to and replaces the correct occurrence
