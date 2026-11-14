# Spec Delta

## Purpose

Make buffer diff readiness and pending computation visible without confusing unavailable data with a completed diff or overwhelming the user with notifications.

## ADDED Requirements

### Requirement: Truthful buffer-local readiness
The system SHALL distinguish initial loading, pending updates, ready results, unavailable data, and computation failures per buffer. Missing data alone MUST NOT imply either ongoing computation or a clean diff. Progress SHALL represent reference acquisition or scheduled/running diff work, not unsaved edits.

#### Scenario: Initial reference acquisition
- **WHEN** reference acquisition has started and no completed diff exists for a buffer
- **THEN** that buffer is reported as loading rather than clean

#### Scenario: Subsequent update
- **WHEN** an enabled buffer with completed results schedules another diff update
- **THEN** it is reported as updating until current results are ready

#### Scenario: No reference available
- **WHEN** reference acquisition ends without a usable reference
- **THEN** the buffer is reported as unavailable, not perpetually loading or clean

#### Scenario: Clean completed result
- **WHEN** computation successfully completes with zero hunks
- **THEN** the buffer is ready with no changes rather than unavailable

### Requirement: Compact progress presentation
The statusline SHALL show `diff: loading…` or `diff: updating…` for the displayed buffer while the corresponding work is pending. It SHALL retain the existing hunk display when ready and SHALL NOT show a busy indicator for unrelated buffers. No animated progress or percentage is required during blocking computation.

#### Scenario: Switch between buffers
- **WHEN** the user switches from a loading buffer to a ready buffer
- **THEN** the statusline reflects the ready buffer rather than retaining the other buffer's progress

#### Scenario: Update finishes
- **WHEN** the latest diff update finishes
- **THEN** the busy indicator disappears and the existing ready-state hunk display resumes, including an empty display for zero hunks

### Requirement: Action feedback reflects readiness
Navigation, preview, selection, and reset SHALL report loading, updating, unavailable, or failed states instead of acting on stale hunks, silently returning, or claiming no hunks. Unavailable and failed feedback SHALL include a reason when known and SHALL NOT invent one. Blocked actions SHALL NOT execute later automatically.

#### Scenario: Preview during loading
- **WHEN** the user requests a hunk preview while its diff is loading
- **THEN** feedback identifies loading for that buffer rather than saying no hunk is under the cursor

#### Scenario: Reset during update
- **WHEN** the user requests reset while current diff results are pending
- **THEN** feedback identifies the pending update and the buffer remains unchanged

#### Scenario: Unavailable or failed computation
- **WHEN** the user invokes a diff action on a buffer with unavailable data or a failed computation
- **THEN** feedback identifies that state and its known reason rather than reporting a clean diff

#### Scenario: Ready but no applicable hunk
- **WHEN** a diff action has no applicable hunk in ready results
- **THEN** feedback distinguishes no changes in the buffer from no hunk under the cursor, as applicable to that action

### Requirement: Non-spamming notifications
Action feedback SHALL use replaceable notifications scoped to the target buffer. Routine progress transitions SHALL NOT create unsolicited notification streams.

#### Scenario: Repeated action while loading
- **WHEN** the user repeatedly invokes diff actions in the same loading buffer
- **THEN** feedback replaces the still-visible notification instead of stacking messages

### Requirement: Progress lifecycle is bounded by current work
Completion, failure, disable, and buffer teardown SHALL clear pending progress. An obsolete completion SHALL NOT overwrite newer results, clear newer progress, or re-enable a disabled buffer.

#### Scenario: Overlapping reference reads
- **WHEN** an older reference read completes after a newer request has started
- **THEN** the older completion does not publish results or mark the newer request ready

#### Scenario: Disable while loading
- **WHEN** the buffer is disabled or unloaded before reference acquisition finishes
- **THEN** progress clears and the late callback does not recreate active diff state

#### Scenario: Computation error
- **WHEN** diff computation raises an error
- **THEN** the buffer leaves the busy state and subsequent actions report the failure

### Requirement: Existing diff behavior remains compatible
The system SHALL preserve ready-state hunk navigation, preview, selection, overlay settings, native diff-window navigation, and read-only review protections. Staged diff SHALL NOT be added by this change.

#### Scenario: Native diff window
- **WHEN** navigation is invoked in a native diff window
- **THEN** existing native diff navigation continues without requiring MiniDiff readiness

#### Scenario: Read-only review
- **WHEN** a reset action is invoked in a read-only review buffer
- **THEN** existing reset protection remains in force and content is not modified

#### Scenario: Ready diff interaction
- **WHEN** a buffer has current, ready hunks
- **THEN** existing hunk operations and end-of-list navigation behavior remain available
