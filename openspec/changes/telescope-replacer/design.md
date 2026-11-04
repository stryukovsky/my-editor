# Design

## Context

The pretty picker facade exposes the existing live grep wrapper. That wrapper supports a regex escape hatch, and the shared Telescope-to-Trouble action can transfer a multi-selection and edit the selected file. The replacer needs byte ranges for every occurrence, a complete review set, and focus in Trouble on handoff.

## Goals / Non-Goals

Keep match discovery in the picker and replacement session state in a local feature module. Reuse the repository's Trouble source registration, item navigation, and notification patterns. Limit the workflow to single-line literal queries and replacement text.

## Decisions

- Add a picker entry through the pretty picker facade and register `:TelescopeReplacer` through its setup. Run ripgrep asynchronously using an argument vector with `--json --fixed-strings --case-sensitive -e`. Decode each submatch into an absolute path, one-based line, zero-based byte range, and original line text. Give each submatch its own styled row using the existing picker display and preview conventions. Plain vimgrep rows omit exact submatch ranges needed by the editor.
- Associate results with the current prompt generation, cancel superseded searches, and transfer only a completed result set. Use the same explicit limit for picker transfer and Trouble rendering. When the search exceeds the limit, ask the user to narrow it. This keeps the confirmation count aligned with what the user could review.
- Add a dedicated Trouble source and mode following `minidiff_review`. Focus the view on the selected occurrence and refresh it from the current session after edits. Bind the mode's Normal-mode `r` and `R` actions through the repository mapping convention. Use the active session's remaining occurrence set for `R`, so folds do not change the scope. Use the existing input UI and a Yes/No confirmation that defaults to No.
- Preflight the selected targets against current file buffers. Check each target line and byte range against the session snapshot, and reject missing, readonly, or otherwise uneditable targets before mutating. Preserve unrelated unsaved changes. Recheck the session and targets after interactive prompts and apply the batch synchronously, from later ranges to earlier ones, with Neovim buffer APIs. Update the stored line and shift later byte columns after a single edit. Ordinary buffer save and undo avoid the separate persistence and recovery behavior of direct filesystem writes.

## Risks / Trade-offs

- Ripgrep searches on-disk text. A changed target line in an unsaved buffer makes that occurrence stale. A new search after saving produces a fresh review set.
- Multiple results on one line require byte-based offsets throughout, including preview and Trouble navigation. Exercise Unicode before and inside a match and replacements of different byte lengths.
- An unexpected error after preflight can leave a partially applied batch. Keep applied edits undoable, report the failure, and reconcile the view with the edits that succeeded.
