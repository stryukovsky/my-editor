# Design

## Context

See `proposal.md` for motivation and scope. This change crosses the local MiniDiff implementation and Moonshine's action/statusline integration, so explicit lifecycle ownership matters.

- `MiniDiff.get_buf_data()` returns nil when disabled, but enabled buffers can also have no reference text. Neither condition proves loading or a clean diff.
- Git attachment/reference reads are asynchronous (`H.git_start_watching_index`, `H.git_set_ref_text`). Their callbacks currently have no request-generation protection.
- `H.schedule_diff_update` debounces work; `H.update_buf_diff` calls synchronous `vim.diff`. `MiniDiffUpdated` fires on successful computation, but not all early-return paths.
- `moonshine.diff.nav` silently returns without data; `hunks.view_hunk` conflates missing data and no cursor hunk. Reset wrappers suppress errors with `pcall`.
- `moonshine.diff.lualine_hunks` already owns the statusline seam. `integrations.notify.replace` already supports keyed replacement.
- Despite the repository guide's historical “No tests” note, `tests/` contains runnable headless Lua regression scripts to follow.

## Goals / Non-Goals

**Goals:** One authoritative lifecycle state at the engine layer, cheap presentation reads, and shared readiness checks across user actions. Instrument real pending work rather than infer it from missing summaries.

**Non-Goals:** Moving computation off-thread, changing Git reference semantics, adding providers/configuration knobs, or redesigning the ready-state statusline. Staged review remains a follow-up.

## Decisions

### 1. Engine-owned state with a small read-only consumer contract

Expose a cheap lifecycle snapshot through `MiniDiff.get_buf_state(buf)` and a separate `MiniDiffStateChanged` User event. State contains `status` (`loading`, `updating`, `ready`, `unavailable`, `failed`) and an optional reason. No active state maps to unavailable in the integration with a neutral “Diff is not enabled for this buffer” explanation.

Record state where work actually starts/ends: attachment, reference acquisition, scheduled updates, computation, source failure, disable, and teardown. Keep `MiniDiffUpdated` semantics and existing summary fields intact. Do not use `get_buf_data()` deep copies for each statusline render.

Alternative rejected: deriving readiness from `minidiff_summary`, reference nil, or elapsed time. These cannot distinguish pending work from a completed unavailable state.

### 2. Track attachment identity and current reference requests

Associate asynchronous Git callbacks with both an enable/attachment identity and a monotonically increasing reference-request token. Check both before applying reference text or publishing completion. Invalidate identities on disable, detach, and source fallback. A late callback must never call `set_ref_text` on an obsolete attachment, because that API can enable a buffer again.

Keep reference-pending state separate from diff-update-pending state internally. A computation using the old reference must not mark a buffer ready while a newer reference request is still pending. Only current reference results and the latest buffer revision can settle ready. Cover debounce scheduling, early returns, nil references, spawn failure, and computation exceptions with terminal transitions.

Alternative rejected: a single busy boolean cleared on any `MiniDiffUpdated` event; overlapping reference and buffer updates make that inaccurate.

### 3. Keep source failure reasons honest and bounded

Missing references or exhausted attachment sources become unavailable, with a generic reason when the existing source cannot distinguish the cause. Explicit process-launch or computation exceptions become failed. Do not infer “untracked,” “ignored,” or “not a repository” from an undifferentiated Git failure. Preserve source fallback and manual reference sources used by reviews; installing reference text schedules an update and can recover from unavailable/failed states.

Alternative rejected: adding Git probes solely to classify every missing-reference case; this would broaden the feature and add process overhead.

### 4. Shared action guard, not delayed action replay

Add a small `moonshine.diff.feedback` module consuming the state snapshot. Navigation, preview (including direct calls to `hunks.view_hunk`), selection, and reset use its readiness guard before reading hunks. Pending actions return with feedback and never queue navigation or destructive operations for later.

Use `notify.replace` with a key scoped to the buffer, a MiniDiff title identifying the buffer, and concise state-specific messages. Ready results distinguish zero hunks from no cursor hunk. Preserve native diff navigation before the guard and review reset protection before mutation. Surface actual operation failures instead of blindly swallowing them. Global overlay toggling continues to express the requested global setting; it does not claim current-buffer readiness.

Alternative rejected: separate checks at each call site, which would recreate today's inconsistent messages.

### 5. Static pending labels in the existing statusline component

Have `lualine_hunks` return `diff: loading…` or `diff: updating…` while pending and otherwise preserve its current ready hunk text (including an empty string for zero hunks). Unavailable/failed states have no unsolicited toast stream; actions explain them. State-change events request statusline refresh outside rendering; rendering remains side-effect free.

`vim.diff` blocks Neovim's main thread. These labels cover reference loading and queued/debounced updates, but cannot animate or guarantee a paint during synchronous computation. Do not introduce forced redraws inside the computation or claim percentage progress.

## Risks / Trade-offs

- [Synchronous computation can freeze the UI] → State this limitation; offloading computation is explicitly excluded.
- [Overlapping reference reads and queued updates can settle out of order] → Attachment identity, request tokens, and tests with controlled callback ordering.
- [Custom/manual sources may not expose detailed failures] → Neutral unavailable reasons, no fabricated diagnostics, and recovery through existing reference-setting APIs.
- [Frequent edits create frequent state changes] → Emit only actual transitions and reuse existing scheduling; no new polling or spinner timer.
- [Engine-local additions increase fork maintenance] → Keep the state contract additive and isolated; preserve upstream summary/update behavior.

## Migration Plan

No data or configuration migration. Apply engine instrumentation first, then integration guards/presentation, then focused regression proof. Roll back by reverting only this change's implementation edits; existing source selection, mappings, and stored data remain unchanged.
