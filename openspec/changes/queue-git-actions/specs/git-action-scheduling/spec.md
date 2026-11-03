# Spec Delta

## Purpose

Coordinate supported Git actions so fetch and pull requests can wait their turn while write actions are rejected before the user spends time entering input.

## ADDED Requirements

### Requirement: Queue state stays in the current session

The action queue and busy state SHALL exist only in memory for the current Neovim session. They SHALL NOT be saved to disk, restored after restart, or shared with another Neovim process.

#### Scenario: Restart Neovim
- **WHEN** Neovim is closed with requests waiting and a new session is opened
- **THEN** the new session has no saved queue or busy state to restore

### Requirement: Fetch and pull wait in submission order

The system SHALL serialize supported Git actions within the current Neovim session. Explicit fetch and pull requests submitted while the session is busy SHALL queue in FIFO order and execute once after earlier work ends. Pull SHALL retain its existing rebase and autostash behavior.

#### Scenario: Pull waits for background fetch
- **WHEN** the user requests pull while a background fetch is running
- **THEN** pull is reported as queued and starts after that fetch finishes without requiring another keypress

#### Scenario: Multiple explicit requests
- **WHEN** fetch and then pull are requested while the session is busy
- **THEN** they run once each in that order, without overlapping another supported action

### Requirement: Writes are rejected before action input

Write actions SHALL be rejected immediately when the session is busy. Rejection SHALL precede action-specific input, confirmation, and mutation, identify the active action, and SHALL NOT enqueue the write. This applies to commits, merges, pushes, renames, amends, and other supported mutations except queueable pull.

#### Scenario: Commit shortcut during fetch
- **WHEN** the user presses `<leader>gc` while a fetch is running
- **THEN** a busy warning identifying fetch appears immediately, no commit-message input opens, and no commit runs after fetch completes

#### Scenario: Rename or amend during pull
- **WHEN** the user invokes branch rename or commit amend while pull is running
- **THEN** the action is rejected before name/message input opens and no mutation is queued

#### Scenario: Stage during another action
- **WHEN** the user requests staging while another supported action is running
- **THEN** staging is rejected immediately rather than queued for later

### Requirement: Interactive writes retain admission

An interactive write admitted while idle SHALL keep the session busy through input, confirmation, and all execution steps. Background fetch SHALL NOT start during this time. Cancellation, success, failure, and launch errors SHALL release admission. Explicit fetch/pull requests SHALL wait behind the reservation.

#### Scenario: Timer fires while entering a message
- **WHEN** commit input opened while idle and the periodic-fetch timer fires before submission
- **THEN** the timer does not start a fetch and the commit can proceed without a late background-fetch rejection

#### Scenario: Cancel message with pull waiting
- **WHEN** pull is queued behind commit input and the user cancels the input
- **THEN** no commit runs and pull can start immediately

#### Scenario: Compound write
- **WHEN** commit-and-push is admitted and fetch is requested before push finishes
- **THEN** fetch waits until the entire commit-and-push flow ends

### Requirement: Repository context remains stable

Queued execution SHALL use the captured target repository and request arguments. All repositories in the current Neovim session SHALL share the same busy state and queue.

#### Scenario: Editor directory changes
- **WHEN** pull is queued for repository A and the editor changes to repository B
- **THEN** the queued pull still runs in A

#### Scenario: Busy state is shared across repositories
- **WHEN** background fetch is running in A and the user requests commit in B in the same Neovim session
- **THEN** commit is rejected before input opens because the session is busy

### Requirement: Completion and failure advance the queue

Every terminal outcome of active work SHALL release admission and advance waiting requests. Each queued action SHALL retain existing execution-time safeguards. Unsafe requests SHALL report their rejection and leave the queue; failures SHALL NOT silently discard later requests or leave the session permanently busy.

#### Scenario: Fetch fails with pull waiting
- **WHEN** a background fetch fails while pull is queued
- **THEN** fetch failure is handled normally and pull receives its turn subject to its existing safeguards

#### Scenario: Command cannot start
- **WHEN** an admitted action fails to launch with a fetch request waiting
- **THEN** its error is reported, admission is released, and the waiting fetch receives its turn

### Requirement: Background fetch uses the same queue

Background fetch SHALL use the same queue and busy state as other actions. Timer ticks SHALL be skipped while the session is busy rather than accumulate requests. Accepted requests SHALL use FIFO order without special priority. Existing lock/unfinished-operation checks, periodic timing, and failure backoff SHALL remain effective.

#### Scenario: Repeated timer ticks while busy
- **WHEN** periodic-fetch ticks occur while an action or write input keeps the session busy
- **THEN** no timer-generated queue accumulates

### Requirement: Entry points share admission without blocking browsing

Git mappings, Neo-tree aliases, and supported branch/commit/remote picker mutations SHALL apply the same policy. Picker direct shortcuts and menu choices SHALL guard writes before their input or confirmation. Browsing, previews, and yank actions SHALL remain available while Git work is active, with existing mutation safeguards preserved.

#### Scenario: Picker merge during fetch
- **WHEN** the user chooses Merge branch from a menu or invokes its direct shortcut during fetch
- **THEN** the merge is rejected before its confirmation and no merge runs

#### Scenario: Inspect commits while busy
- **WHEN** the user browses commits, opens a preview, or yanks a SHA while fetch runs
- **THEN** the interaction remains available without waiting for fetch
