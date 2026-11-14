---
name: lazyspec-propose
description: Draft a proposal and short tasks for human review. Use when the user says propose or wants to plan a change before implementation.
license: MIT
---

# Propose

Create a reviewable plan using repository files. Planning never authorizes implementation.

## Response style

Use Caveman style in chat until the user says "stop caveman" or "normal mode". Answer first. Cut filler.
Keep one idea per sentence. Use familiar words and at most 20 words. Clarity wins.
Preserve technical facts and negations. Keep code and commands unchanged. Keep paths and identifiers exact.
Keep tool updates brief. No decorative tables or emoji. Use the user's language. Never imitate broken grammar.
Use full sentences for questions and safety warnings. Confirm irreversible actions. Preserve existing comments unless asked to change them.
Use plain prose in saved artifacts. Required workflow steps and output formats take priority over style.

## Steps

1. Read project instructions and relevant code. Inspect existing `openspec/specs/` and active `openspec/changes/` folders.
2. Clarify only questions that change scope or behavior. Do not invent decisions the user must make.
3. Choose a short kebab-case change name. Create `openspec/changes/<name>/` when the user requests this workflow.
4. Write `proposal.md` with these sections:
   - `## Why`: the problem in one or two sentences.
   - `## Changes`: short bullets describing observable behavior.
   - `## Acceptance`: concrete outcomes the user can review.
   - `## Out of scope`: only boundaries that prevent likely scope creep.
5. Write `tasks.md` using the rules below.
6. Add `design.md` only for decisions that need explanation. Add `specs/<capability-path>/spec.md` only when separate behavior detail helps review. Reuse existing capability paths.
7. Show the proposal path and short task list. Highlight unresolved decisions. Stop for human review.

## Tasks

- Group related work under short numbered headings.
- Use `- [ ] 1.1 Task description` checkboxes.
- Use 3-7 words per description excluding checkbox and number.
- Put one concrete action on each line.
- Never use commas or semicolons in descriptions.
- Split compound actions into more tasks. Do not combine coding and verification.
- Keep test tasks beside the work they check. Split distinct test cases.
- Keep rationale and long commands outside task descriptions. Preserve exact identifiers when needed.
- Do not add work beyond the approved scope to increase task count.

```md
## 1. Buffer feedback

- [ ] 1.1 Add readonly buffer snapshot
- [ ] 1.2 Emit buffer state changes
- [ ] 1.3 Verify initial loading state
- [ ] 1.4 Verify existing hunks load
- [ ] 1.5 Verify zero-hunk ready state
```

## Boundaries

Do not edit implementation files. Do not commit or update permanent specs.
Do not start implementing after drafting even if the original request says "build" or "fix".
Wait for a new explicit implementation request after the user reviews the proposal.
