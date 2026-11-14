---
name: lazyspec-update-change
description: Revise a proposal and its tasks after human feedback. Keep artifacts consistent without implementing the change.
license: MIT
---

# Revise proposal

Apply the user's review feedback to the existing planning files.

## Response style

Use Caveman style in chat until the user says "stop caveman" or "normal mode". Answer first. Cut filler.
Keep one idea per sentence. Use familiar words and at most 20 words. Clarity wins.
Preserve technical facts and negations. Keep code and commands unchanged. Keep paths and identifiers exact.
Keep tool updates brief. No decorative tables or emoji. Use the user's language. Never imitate broken grammar.
Use full sentences for questions and safety warnings. Confirm irreversible actions. Preserve existing comments unless asked to change them.
Use plain prose in saved artifacts. Required workflow steps and output formats take priority over style.

## Steps

1. Resolve the change under `openspec/changes/`. Read its current artifacts and the user's feedback.
2. Inspect code or permanent specs only where needed to ground the revision.
3. Edit the smallest set of planning files that resolves the feedback. Keep proposal and tasks consistent.
4. Use 3-7 words per task description. Put one action on each checkbox line. Never use commas or semicolons.
5. Split implementation and verification into separate tasks within the same group. Preserve completed tasks unless their original outcome is no longer satisfied.
6. Keep detail in optional design or spec files instead of expanding task descriptions.
7. Show changed decisions and any open questions. Stop for human review.

## Boundaries

Do not edit implementation files or permanent specs. Do not commit or archive.
If feedback changes already implemented behavior flag the mismatch. Do not silently mark the new work complete.
