---
name: openspec-archive-change
description:
  Finalize an implemented change by updating permanent specs and archiving its
  proposal with a scoped commit. Use when the user says finalize or asks to
  finish and commit a change.
license: MIT
---

# Finalize

Finish the user's reviewed change. Promote its accepted behavior into permanent
specs and preserve the proposal history.

## Response style

Use Caveman style in chat until the user says "stop caveman" or "normal mode".
Answer first. Cut filler. Keep one idea per sentence. Use familiar words and at
most 20 words. Clarity wins. Preserve technical facts and negations. Keep code
and commands unchanged. Keep paths and identifiers exact. Keep tool updates
brief. No decorative tables or emoji. Use the user's language. Never imitate
broken grammar. Use full sentences for questions and safety warnings. Confirm
irreversible actions. Preserve existing comments unless asked to change them.
Use plain prose in saved artifacts. Required workflow steps and output formats
take priority over style.

## Steps

1. Resolve the selected folder under `openspec/changes/`. Read its proposal and
   tasks plus any design or spec files.
2. Inspect repository status and the actual implementation diff. Identify
   exactly which files belong to this change.
3. Check acceptance outcomes and task completion. Run relevant checks. Stop on
   unfinished work or failures. Ask about unavailable checks rather than
   claiming success.
4. Promote accepted behavior using `openspec-sync-specs`. Wait for that work to
   finish. For changes without behavior changes leave permanent specs alone.
5. Compare permanent specs against the implemented result. Do not archive while
   the specs contradict the result.
6. Move the change folder to `openspec/changes/archive/YYYY-MM-DD-<name>/`.
   Reuse an existing date prefix. Never overwrite an existing archive.
7. Review the final diff including spec updates and the archived artifacts.
   Stage only paths belonging to this change. Never use blanket staging.
8. Inspect the staged diff. If unrelated changes are already staged stop and ask
   without unstaging them. If a file mixes unrelated edits ask before staging
   it.
9. Create one descriptive commit for the change. A finalize request authorizes
   this scoped commit unless the user explicitly excludes committing.
10. Report the commit hash and updated spec paths. If committing fails report
    the failure and current artifact locations. Do not pretend finalization
    succeeded.

## Boundaries

Never push or amend unless separately requested. Never reset or discard
unrelated work. Do not move a whole proposal over an existing permanent spec.
Merge behavior while preserving unrelated requirements. Keep historical proposal
and task files in the archive. Do not copy planning checkboxes into permanent
behavior specs. If specs or implementation live in a different repository ask
how commits should be split before writing or moving files.
