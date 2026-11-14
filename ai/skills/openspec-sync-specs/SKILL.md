---
name: openspec-sync-specs
description: Promote approved implemented behavior from a proposal into permanent specs using direct file edits. Preserve unrelated requirements.
license: MIT
---

# Update permanent specs

Maintain `openspec/specs/` as the description of delivered behavior. Proposals remain plans until implementation is accepted.

## Response style

Use Caveman style in chat until the user says "stop caveman" or "normal mode". Answer first. Cut filler.
Keep one idea per sentence. Use familiar words and at most 20 words. Clarity wins.
Preserve technical facts and negations. Keep code and commands unchanged. Keep paths and identifiers exact.
Keep tool updates brief. No decorative tables or emoji. Use the user's language. Never imitate broken grammar.
Use full sentences for questions and safety warnings. Confirm irreversible actions. Preserve existing comments unless asked to change them.
Use plain prose in saved artifacts. Required workflow steps and output formats take priority over style.

## Steps

1. Resolve the change under `openspec/changes/`. Read its proposal and optional spec files. Confirm the user requested promotion or finalization.
2. Read the affected permanent specs in full. Match existing capability paths instead of inventing near-duplicates.
3. If the implementation is not accepted stop before promoting planned behavior. Compare approved outcomes with the actual delivered change.
4. Merge only the intended additions and changes into `openspec/specs/<capability-path>/spec.md`.
5. For a new capability create a concise spec with its purpose and observable behavior. Use accepted proposal content when no separate spec exists.
6. Preserve existing headings and unrelated requirements. Keep scenarios that still apply. Remove behavior only when explicitly approved.
7. For existing delta documents apply ADDED and MODIFIED entries to their named requirements. Apply REMOVED and RENAMED entries explicitly. Stop if a target is missing or ambiguous.
8. Read each resulting spec. It must describe current behavior rather than pending changes. Remove delta-operation headings from newly merged content.
9. Report updated paths and any unresolved mismatch.

## Boundaries

Do not replace an established spec with the entire proposal. Do not copy task lists or design rationale into behavior requirements.
If behavior cannot be mapped to a capability ask rather than writing to an arbitrary destination.
Repeated promotion should not duplicate requirements. Do not archive or commit here; finalization handles those steps.
