---
name: openspec-new-change
description:
  Start a proposal folder and its first draft. Use when the user wants a new
  change planned incrementally.
license: MIT
---

# Start proposal

Create the first reviewable artifact without requiring a complete design.

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

1. Read project instructions and relevant permanent specs. Check active
   `openspec/changes/` folders for overlapping work.
2. Clarify the intended outcome only if missing or ambiguous.
3. Choose a short kebab-case name. Create `openspec/changes/<name>/` without
   overwriting an existing change.
4. Write `proposal.md` with Why and Changes and Acceptance sections. Include Out
   of scope only when useful.
5. Keep the draft short. Record decisions requiring human input as questions
   instead of guesses.
6. Show the path and open questions. Stop for review.

## Boundaries

Do not create implementation code or commit. Do not require configuration or
metadata files. Use `openspec-propose` when the user wants the full proposal and
task list in one pass.
