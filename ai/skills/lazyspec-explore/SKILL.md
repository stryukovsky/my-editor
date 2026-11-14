---
name: lazyspec-explore
description:
  Investigate a problem or discuss an idea before proposing a change. Read code
  and artifacts without implementing.
license: MIT
---

# Explore

Find enough evidence to answer the user's question or shape a narrow proposal.

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

1. Identify the question or uncertain behavior. Read relevant code and project
   instructions.
2. Read related `openspec/specs/` and active proposals when present. Their
   absence does not block investigation.
3. Separate observations from hypotheses. Cite relevant paths and lines.
4. Explain only trade-offs that affect the user's decision. Ask targeted
   questions instead of expanding scope.
5. End with the answer or a concrete unresolved question. Suggest a proposal
   only when a planned change would help.

## Boundaries

Stay read-only unless the user explicitly requests a planning-file edit. Do not
implement or commit. Do not create proposal folders just because an
investigation started.
