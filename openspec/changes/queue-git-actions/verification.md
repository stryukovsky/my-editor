# Verification

Verified on 2026-11-03 using headless Neovim and disposable local Git repositories.

## Focused checks

A temporary Lua harness ran 63 assertions against the changed modules. It used
controlled job callbacks to exercise concurrency and errors, real Git commands
for picker mutations, and real asynchronous Git jobs for commit → pull → fetch
against a local bare remote. No network remote or personal repository was changed.

Passed:

- Background fetch owns the shared session busy variable. Manual pull and fetch
  wait in FIFO order and retain their original repository after cwd changes.
- All command write entry points reject while busy, including calls with
  Neo-tree state. Busy warnings identify the active action. No input opens and
  rejected actions never enter the queue.
- Commit input reserves the session. Empty input and cancellation clear it and
  start the next request. Repeated timer ticks skip rather than queue.
- The actual configured commit input float opens while idle; closing its window
  cancels input and releases a waiting fetch.
- Commit-and-push and checkpoint hold busy state between steps. Waiting fetch
  starts only after the whole action ends.
- Background-fetch failure, explicit-pull failure, input exceptions, and command
  spawn exceptions release busy state. Later requests still run. Background spawn
  exceptions deliver failure to their callback.
- A queued pull encountering a Git lock is reported and skipped; the following
  request runs. Existing lock and unfinished-operation checks were retained.
- Background-fetch retry backoff and the normal interval after success still
  work. Sync-state refresh and callback calls remain in the completion path.
- Every branch and commit mutation handler rejects while busy. The real shared
  action-menu router was exercised with headless picker/UI doubles for direct
  shortcuts and menu choices. Remote direct and menu routes also reject before
  input.
- Branch rename and commit amend still execute against real repositories when
  idle. HEAD changes during amend input are rejected. Older-commit mutations and
  remote-tracking branch rename remain rejected. Canceled delete/undo leaves
  branches and HEAD intact.
- Remote input cancellation clears busy state. HTTP-to-SSH conversion keeps busy
  state through both inputs and changes the URL only after final submission.
- Revert confirmation cancellation starts waiting work. Duplicate submit/close
  callbacks cannot end a running revert or release the next action accidentally.
- Custom history/review mapping callbacks retain ownership. Menu browsing and
  yank work while busy. Preview implementations and read-only display paths were
  inspected and are unchanged and outside admission guards.
- Queue and busy state are module-local memory only, with no persistence or
  cross-process coordination.

The harness lived at `/tmp/queue-git-actions-check.lua`; no test framework was
added to the configuration repository. Picker rendering was represented by UI
and picker doubles; no manual desktop rendering check was performed.

## Final checks

- Lua compilation with `loadfile` under `nvim --headless -i NONE -u NONE -n`:
  passed for all seven changed/new Lua files.
- Bundled StyLua formatting and `--check`: passed for the same files.
- `git diff --check`: passed.
- `openspec validate queue-git-actions --strict`: passed.
- Plugin specs and `lazy-lock.json`: unchanged by this implementation.
- Existing staged edits to `lua/configs/neotree.lua` and
  `lua/mappings/neotree_git_status.lua` were left untouched; their Git aliases
  already point to the shared command handlers.
