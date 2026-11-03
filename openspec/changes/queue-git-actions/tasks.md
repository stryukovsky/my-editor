# Tasks

## 1. Track the running Git action

- [x] 1.1 Use one shared busy variable for the current Neovim session. Check
      that every supported action reads the same variable.
- [x] 1.2 Set the busy variable before opening write input. Check that
      canceling input clears it.
- [x] 1.3 Clear busy state when an action succeeds, fails, or cannot start.
      Check each case.
- [x] 1.4 Include the running action in busy warnings. Check that a running
      fetch is named in the warning.

## 2. Queue fetch and pull

- [x] 2.1 Add one in-memory queue for the current Neovim session. Check that
      requests run in order and nothing is saved or restored across restarts.
- [x] 2.2 Put manual fetch requests in the queue when busy. Check that they run
      once when the current action ends.
- [x] 2.3 Put pull requests in the queue when busy. Check that pull still uses
      rebase and autostash.
- [x] 2.4 Show a notification when a request is queued. Check that it names the
      action and repository.
- [x] 2.5 Save the repository and arguments with each request. Check that
      changing the editor directory does not change the queued action's target.
- [x] 2.6 Start the next queued request after success or failure. Check that a
      failed request does not block later requests.
- [x] 2.7 Recheck existing safety conditions before running a queued request.
      Check that an unsafe request is reported and removed without blocking the
      rest.

## 3. Connect background fetch

- [x] 3.1 Make background fetch use the same queue and busy variable as other
      actions. Check that it cannot run alongside another action.
- [x] 3.2 Start the next queued request when any action ends. Check background
      fetch and other actions on success, failure, and failure to start.
- [x] 3.3 Skip timer fetch while an action or input is active. Check that
      repeated timer ticks do not add queued requests.
- [x] 3.4 Keep existing lock checks, retry delays, callbacks, and sync-state
      updates. Check that they still work after the change.

## 4. Block write actions early

- [x] 4.1 Check the busy variable at the start of every write action, before
      input or confirmation. Check commit, merge, push, rename, and amend;
      `<leader>gc` during fetch is one example that must open no input.
- [x] 4.2 Keep the session busy while the user writes a commit message. Check
      that timer fetch cannot start while input is open.
- [x] 4.3 Clear session busy state when commit input is canceled or empty. Check
      that a waiting pull can then start.
- [x] 4.4 Block branch creation and rename before opening name input. Check both
      actions while fetch is running.
- [x] 4.5 Block push, merge continue/abort, stash/pop, checkpoint, and revert
      while busy. Check that no rejected action runs later or opens a
      confirmation.
- [x] 4.6 Replace stage/unstage queueing with immediate rejection while busy.
      Check that neither action runs later.
- [x] 4.7 Keep commit-and-push and checkpoint busy through all their steps.
      Check that queued fetch cannot run between steps.
- [x] 4.8 Keep existing command arguments, refreshes, and result messages.
      Compare their behavior before and after the change.

## 5. Use the same rules in pickers

- [x] 5.1 Block branch switch, delete, merge, rebase, and rename while busy.
      Check direct shortcuts and menu choices before input or confirmation
      opens.
- [x] 5.2 Block commit checkout, amend, and undo while busy. Check direct
      shortcuts and menu choices before input or confirmation opens.
- [x] 5.3 Block remote edits before opening input while busy. Check that
      canceling an allowed edit clears session busy state.
- [x] 5.4 Keep existing HEAD checks, selection checks, and confirmations. Check
      that they still reject invalid actions when the repository is idle.
- [x] 5.5 Keep browsing, previews, and yanking available while busy. Check each
      during fetch.

## 6. Document and check the full flow

- [x] 6.1 Update the Git tools README with which actions queue and which are
      blocked. Check that it matches the implemented behavior.
- [x] 6.2 Try fetch → queued pull and fetch → blocked commit in disposable
      repositories. Record the results in verification.md.
- [x] 6.3 Check the same rules through Neo-tree aliases and picker menus. Record
      the results in verification.md.
- [x] 6.4 Check that changing repositories still uses the same session queue
      and busy variable, while queued requests keep their original target.
      Record the result in verification.md.
- [x] 6.5 Run Lua syntax, formatting, and diff checks. Record the results in
      verification.md.
- [x] 6.6 Run `openspec validate queue-git-actions --strict`. Check that it
      passes and that plugin dependencies and lazy-lock.json are unchanged.
