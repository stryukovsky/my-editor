---
name: openspec-ff-change
description:
  Draft a complete proposal and narrow tasks in one pass. Use when the user
  wants planning completed without intermediate drafting checkpoints.
license: MIT
---

# Draft complete plan

Use the `openspec-propose` workflow to draft the planning files in one pass.
This is a planning shortcut only.

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

1. Read project instructions and relevant code and permanent specs.
2. Resolve material ambiguity before drafting. Do not invent product decisions
   to avoid questions.
3. Create `openspec/changes/<name>/proposal.md` with Why and Changes and
   Acceptance sections.
4. Create `tasks.md` with numbered checkboxes. Each description has one action
   and 3-7 words. No commas or semicolons.
5. Split verification into separate tasks beside implementation. Include only
   work required for the proposal.
6. Create optional design or spec files only when necessary. Do not expand short
   tasks into design paragraphs.
7. Present the paths and task list. Stop for human review.

## Boundaries

Do not implement after planning. Wait for a new explicit implementation request.
Do not commit or promote permanent specs.
