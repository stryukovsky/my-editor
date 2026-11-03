# Design

## Context

See proposal.md for the user-visible problem. `commands.lua` has per-root busy flags and a private stage/unstage queue. It checks the separate, global `fetch.fetch_pending` flag only when executing a command; `input_command` has already collected input by then. The background-fetch completion callback never drains the command queue. Picker mutations mostly call synchronous `git.run` directly; remote editing has another late busy check.

## Goals / Non-Goals

Goals:

- One admission boundary shared by supported mutations and background/manual fetch/pull execution.
- Stable repository and action context through asynchronous input and queue delays.
- Preserve existing confirmations, HEAD checks, error reporting, refreshes, and compound command behavior.

Non-goals:

- Scheduling arbitrary terminal commands, external Neovim processes, or third-party plugin internals.
- Queue persistence, queue-management UI, generic job infrastructure, or changes to pull conflict resolution.
- Serializing ordinary status/log/diff reads and previews.

## Decisions

### Explicit action policy, serialized execution

Introduce a small shared module under `moonshine.git` rather than adding another independent busy flag to each caller. Callers declare the action type rather than inferring it from command arguments.

| Policy | Existing actions |
| --- | --- |
| Queue when busy | Explicit fetch; pull with rebase and autostash |
| Reject before action input when busy | Commit, commit-and-push, checkpoint, push, merge/continue/abort, branch create/rename/delete/switch/rebase, commit checkout/amend/undo, stash/pop, stage/unstage/revert, remote edits |
| No scheduling | Browsing lists, previews, status/log/diff reads, yanking names/SHAs |

Pull remains serialized because it changes the local branch and worktree. "Queueable" describes the requested UX, not Git's read/write semantics. Broadly queueing writes was rejected because it could apply a mutation long after its initiating interaction.

### Keep one queue and one busy variable in memory

Use one shared Lua variable for the active action, including time spent entering write input, and one FIFO queue for the current Neovim session. Store both in the shared module; do not save them to disk or coordinate separate Neovim processes. Capture each action's repository and arguments when requested so changing cwd does not change its target. Existing busy accessors must read this shared state rather than keep separate flags.

Background fetch uses the same queue, busy variable, and completion path as other actions. Busy state applies across repositories within this session; separate per-repository scheduling is unnecessary. Existing Git lock and unfinished-operation checks remain necessary for external activity.

### Reserve before opening write input

At a concrete write action's entry point, acquire admission before opening message/name input, mutation confirmation, or performing preparatory mutation. `<leader>gc` reaches this boundary immediately. Picker browsing and action-menu discovery stay available; choosing a write action or pressing its direct shortcut reaches the guard before its input/confirmation.

An admitted interactive flow holds a reservation until it cancels, fails, or completes. Timer fetches skip while the session is busy. Explicit fetch/pull requests wait behind the reservation. This avoids the race where a simple preflight check passes and a background fetch starts while the user types. Holding a reservation can delay refresh while input stays open; cancellation releases it immediately.

Compound actions retain one reservation through all steps, including commit-and-push and checkpoint. Existing execution-time HEAD and selection checks remain; admission does not replace them. Wrap synchronous and asynchronous failure paths so reservations are released exactly once.

### Start the next request whenever an action ends

Accept each explicit fetch/pull request once into FIFO order, with an immediate queued notification. Submit background fetch through the same queue only when idle. When the current action or reservation ends, start the next request without an intervening admission window. Background-fetch success, failure, and spawn errors use the same release path. Failed requests are reported and removed; subsequent requests still receive their normal safety checks. If a queued request becomes unsafe, report and discard that request rather than executing it blindly or wedging the queue.

Periodic fetch retains its existing skip/backoff behavior when busy; do not accumulate timer ticks. All accepted requests use ordinary FIFO order with no separate timer or user priority. Preserve the background callback, retry timing, sync-state updates, and existing post-command refresh behavior.

### Keep notifications actionable

Blocked writes name the active action and ask the user to retry after it finishes. They create no delayed work or input buffer. Queued fetch/pull requests identify the requested action and target repository. Existing start/success/failure notifications take over when execution begins; no new queue UI is required.

## Risks / Trade-offs

- A missed picker path bypasses serialization → audit every existing mutation, including direct shortcuts and menu routes, against the policy table.
- Input cancellation or a Lua exception leaves a reservation stuck → use one completion/release path and verify cancellation, spawn exceptions, and nonzero exits.
- Deferred pull acts on changed repository state → retain captured cwd/arguments, recheck existing safety conditions at execution, and retain Git's normal conflict/error handling.
- External Git commands remain outside this scheduler → preserve existing lock checks and report Git failures without automatic retries of mutations.

## Migration Plan

Introduce shared admission, connect background fetch and command execution, then migrate picker mutations. Remove obsolete independent queue/busy decisions after all consumers are covered. Document the policy in the Git tools README. Verify in disposable repositories before using real worktrees. Rollback restores the former command/fetch/picker admission paths; queues are memory-only and require no data migration.
