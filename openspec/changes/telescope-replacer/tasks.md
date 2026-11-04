# Tasks

## 1. Pretty picker and search

- [ ] 1.1 Register `:TelescopeReplacer` and add live ripgrep JSON search with styled occurrence rows and a preview. Verify literal metacharacters, case sensitivity, repeated matches on one line, and Unicode byte columns.
- [ ] 1.2 Bound the search session and guard the Enter handoff. Verify that empty, incomplete, superseded, and over-limit results cannot start a review.

## 2. Trouble review and editing

- [ ] 2.1 Add the dedicated Trouble source and focused review mode. Verify that Enter from either picker mode selects the intended occurrence and that Trouble navigation jumps to the correct file and column.
- [ ] 2.2 Implement target preflight and literal buffer edits. Verify that unrelated unsaved edits survive, changed target lines and readonly buffers are rejected, and changed byte lengths update remaining rows.
- [ ] 2.3 Wire Normal-mode `r` and `R`. Verify single replacement, empty replacement, cancellation, default No, and confirmed replacement of all remaining rows across files, including folded results. Check that the edits can be undone and saved normally.
