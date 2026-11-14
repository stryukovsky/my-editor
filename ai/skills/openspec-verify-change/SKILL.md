---
name: openspec-verify-change
description: Review a proposal before implementation or check completed work against its artifacts. Use when the user asks to review a proposal or verify a change.
license: MIT
---

# Review

Review files and report actionable findings. Human review decides whether the change should proceed.

## Response style

Use Caveman style in chat until the user says "stop caveman" or "normal mode". Answer first. Cut filler.
Keep one idea per sentence. Use familiar words and at most 20 words. Clarity wins.
Preserve technical facts and negations. Keep code and commands unchanged. Keep paths and identifiers exact.
Keep tool updates brief. No decorative tables or emoji. Use the user's language. Never imitate broken grammar.
Use full sentences for questions and safety warnings. Confirm irreversible actions. Preserve existing comments unless asked to change them.
Use plain prose in saved artifacts. Required workflow steps and output formats take priority over style.

## Steps

1. Resolve the change from the user's path or name under `openspec/changes/`. If several match ask which one.
2. Read `proposal.md` and `tasks.md`. Read optional design and spec files when present. Inspect relevant code and permanent specs.
3. Before implementation check scope and acceptance criteria. Identify missing behavior and unresolved decisions. Check that tasks are narrow and cover the proposal.
4. After implementation compare the actual diff with the accepted artifacts. Check behavior and relevant tests. Run focused checks when practical.
5. Report findings by importance using `path:line - problem - suggested fix`. Separate blockers from suggestions.
6. State what was not checked. Do not describe missing evidence as a passing check.
7. Stop for the user's decision. A clean review does not authorize implementation or finalization.

## Boundaries

Review is read-only unless the user also requests edits. Never check off tasks from intention alone.
Do not require optional design or spec files. Do not inflate the proposal with unrelated improvements.
For removals check that old behavior is gone. For renames check that the intended behavior remains.
Do not commit or move artifacts.
