---
name: openspec-bulk-archive-change
description:
  Finalize several explicitly selected changes. Review overlapping spec updates
  and commit each change with a clear scope.
license: MIT
---

# Finalize several changes

Apply the `openspec-archive-change` workflow to each selected change. Never
infer that all active changes are selected.

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

1. List folders under `openspec/changes/` excluding `archive/`. Resolve the
   user's explicit selection.
2. Read selected proposals and tasks. Check their diffs and acceptance outcomes
   before making changes.
3. Identify overlapping code and spec edits. Ask about conflicts or inseparable
   commit scopes before staging anything.
4. Agree on order when changes depend on each other. Do not use folder dates as
   proof of dependency.
5. Finalize each change sequentially using `openspec-archive-change`. Verify
   spec promotion before moving its proposal folder.
6. Commit only that change's files. Preserve unrelated staged and unstaged work.
   Do not push.
7. Stop on a failure. Report completed changes and their commit hashes plus
   changes left untouched.

## Boundaries

Do not bulk-stage the repository. Do not overwrite archives or requirements. If
changes cannot be separated ask whether the user wants a combined commit.
