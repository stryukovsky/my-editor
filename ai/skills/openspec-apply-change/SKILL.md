---
name: openspec-apply-change
description:
  Implement a reviewed proposal when the user explicitly asks to implement. Work
  through its short tasks and verify the results.
license: MIT
---

# Implement

Implement only after the user explicitly approves implementation. A proposal or
review request is not approval.

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

1. Resolve the requested change under `openspec/changes/`. Ask if the selection
   is ambiguous.
2. Read project instructions and the change's `proposal.md` and `tasks.md`. Read
   optional design and spec files when present.
3. Inspect repository status. Preserve unrelated edits and existing user work.
4. Work through unchecked tasks in dependency order. Reuse existing code and
   patterns. Keep each edit within the approved scope.
5. Mark a task `- [x]` only after its action is complete. Mark verification
   tasks only after observing their outcomes.
6. If a decision changes scope or behavior stop and ask. Do not silently rewrite
   the plan to justify different work.
7. Run relevant checks. Report failures and checks not run honestly.
8. Summarize completion and remaining tasks. Stop for human review or an
   explicit finalize request.

## Task format

When splitting a task use 3-7 words per description. Use one action per checkbox
with no commas or semicolons. Keep verification in separate tasks beside the
implementation. Keep numbering unique. Preserve completed work.

## Boundaries

Do not commit or promote artifacts to permanent specs during implementation. Do
not treat checked boxes as proof that behavior is correct. Do not fix unrelated
problems.
