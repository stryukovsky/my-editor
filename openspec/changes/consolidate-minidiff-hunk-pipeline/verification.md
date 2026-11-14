# Implementation verification

## Baseline

Before structural edits, all three existing suites passed:

- `nvim --headless -u NONE -l tests/minidiff_feedback.lua`
- `nvim --headless -u NONE -l tests/minidiff_staged.lua`
- `nvim --headless -u NONE -l tests/minidiff_layers.lua`

## Preserved behavior

The same three suites pass after moving all runtime modules to `mini_diff` and
extracting ownership. They retain their existing assertions for feedback,
staged/saved/unsaved/untracked changes, callbacks, worktrees, projection,
navigation repeat, handoff, mutation safety, review guards, and native diff navigation.
Tests no longer add the removed `diff_tools` directory to runtimepath.

## New focused proof

`nvim --headless -u NONE -l tests/minidiff_pipeline.lua` passes and checks:

- Raw saved and unsaved snapshots remain available while canceled edits create
  no effective target, marker count, or statusline count.
- Saving refreshes the saved baseline without moving effective navigation targets.
- Public snapshot mutation cannot change authoritative engine data.
- Session-singleton kind stores remain isolated.
- Publication rejects obsolete tokens, changed buffer ticks, changed saved-file
  revisions, renamed paths, and cleared attachments.
- Overlay and preview setup are idempotent.
- Overlay toggles add/remove inline extmarks while retaining gutter signs and
  source text, without rereading Git.
- Background overlays use their buffer's text rather than the current buffer.
- Newly enabled buffers adopt the existing global overlay preference.
- The preview facade delegates to the new module and preserves content,
  highlights, read-only flags, detach protection, and explicit deletion cleanup.
- Unicode preview word spans retain byte coordinates. Counted forward/backward
  movement and first/last range selection preserve existing rules.
- Changing to a manual source removes old staged/untracked navigation contributions.
- Real moved review/history modules load and register their commands using the
  merged runtime root. Existing external Git/picker dependencies are stubbed for
  this focused setup check, not the review/history implementations.
- Each moved integration module has exactly one runtime owner under `mini_diff`.

The original Git watcher transport and attachment lifecycle remain in the engine;
reference acquisition/generation coordination now lives in `hunks_loader`.
Compatibility attachment views redirect hunk/state fields into `hunks_cache`
instead of keeping duplicate authoritative engine arrays.

Additional checks pass: `git diff --check` and StyLua checks on the extracted
modules, facade files, and new pipeline suite. Review, history, and feedback
implementation contents were compared with their old tracked paths and are
byte-for-byte unchanged after the move.

## Remaining manual check

Task 5.6 remains open: inspect the configured light and dark themes in an attached
UI. Headless checks prove extmarks, glyph/group selection, and overlay cleanup,
but do not establish actual theme contrast or visual layout in the configured statuscolumn.

Interactive review/history picker workflows were not manually exercised; their
implementation files were moved without behavior edits and existing review
protection/navigation checks pass. No commit or permanent spec promotion was performed.
