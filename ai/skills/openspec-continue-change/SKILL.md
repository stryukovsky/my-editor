---
name: openspec-continue-change
description:
  Continue drafting an existing proposal by adding the next useful planning
  artifact. Never infer implementation approval.
license: MIT
---

# Continue planning

Read what exists and draft only the next useful planning artifact.

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

1. Resolve the selected change under `openspec/changes/`. Ask if several changes
   could match.
2. Read its current files and the latest review feedback.
3. Resolve questions that would change the next artifact before writing it.
4. If the proposal is missing draft it first. Otherwise add tasks. Add design or
   separate specs only when their detail helps review.
5. Write each task as one action using 3-7 words. Use numbered checkboxes
   without commas or semicolons.
6. Put verification in separate tasks beside the work being checked.
7. Show the new artifact path and any remaining questions. Stop for review.

## Boundaries

Do not rewrite existing artifacts unless requested. Use `openspec-update-change`
for revisions. Do not implement or commit. If the plan is complete say it is
ready for human review.
