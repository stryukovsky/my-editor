---
name: introduce-language-integration
description: Add or consolidate Neovim language support in this repository through one shared language definition covering formatting, LSP, DAP, native completion, snippets, TreeSJ, sibling swap, and Tree-sitter. Use when introducing a language or implementing the unified language registry.
---

# Introduce language integration

Make one language definition the source of truth for every applicable integration.
Adding a language must propagate to consumers without editing their language lists.
Unsupported capabilities must remain visible with a reason; installing a binary
does not constitute configuring its integration.

## Establish the current state

Work from the repository root and read `AGENTS.md`. Read
[the integration map](references/integration-map.md) to locate the existing owners
and lifecycle exceptions, then inspect the relevant live files. The map records
the configuration reviewed on 2026-11-03; implementation takes precedence over
stale descriptive lists. Preserve unrelated staged and unstaged work.

Determine whether a unified registry already exists before creating one. If it
exists, extend it. If it does not, introducing the registry and connecting its
consumers is necessary to fulfill a request for unified support; a new language
table that no plugins consume is incomplete. A request only to prepare or revise
this skill does not request the runtime migration.

## Shared ownership

For a first implementation, use the local-feature convention:

- `moonshine.nvim/languages/lua/moonshine/languages/` owns the registry and
  language definitions, preferably one directory per language for associated
  syntax data, snippets, presets, and fixtures.
- Keep setup calls and editor-wide preferences in `lua/configs/`. Plugin glue
  can live in `lua/integrations/`; language-specific choices belong to the
  registry. `lua/plugins/moonshine.lua` discovers the feature automatically.
- Provide shared lookup/collection functions consumed by existing setup modules.
  Do not leave parallel hard-coded language lists in consumers. Keep general
  plugin behavior, UI, and keybindings outside the definitions.

Choose a small Lua contract suited to the existing consumers. Each definition
needs an ID, Neovim filetypes, and explicit identities for its integrations.
Do not equate a filetype, Tree-sitter grammar, Mason package, LSP config name,
Conform formatter, debugger type, or snippet scope: e.g. `typescriptreact` /
`tsx`, `bash` / `sh`, `lua_ls` / `lua-language-server`, `codelldb` shared by
multiple languages. Represent aliases and shared tools once and deduplicate
collected setup/install requests. Deep-copy options before plugins mutate them.

For each of these capabilities, record configured support, inherited upstream
support, external prerequisites, or unsupported status with a reason:

| Capability | Definition supplies / consumer derives |
| --- | --- |
| Formatting | Filetype coverage, ordered Conform formatter IDs, custom definitions, tool provider |
| LSP | Config name, settings/cmd/root overrides, lifecycle owner, Mason package or external provider |
| DAP | Shared adapter reference, per-filetype configurations, lifecycle hook, tool provider, optional templates/schema |
| Completion | Native LSP completion plus optional grammar context mapping and its fixtures |
| Snippets | Existing collection scopes, inheritance, and local snippet assets exposed to the active loader |
| Split/join | Existing TreeSJ preset or verified custom grammar-node presets |
| Sibling swap | Generic parser support, with grammar-specific fallbacks only if needed |
| Tree-sitter | Grammar names, filetype associations, parser dependencies, applicable query overrides |

Also carry existing language-specific neotest adapters/options, Comment.nvim
overrides, refactoring preferences, ast-grep language/patterns, spell string groups,
and custom filetype detection when present. Reuse generic folding, indentation,
rainbow delimiters, diagnostics, hover, and navigation integration automatically.
Do not create new per-language implementations where the upstream plugin already
supports the language. Do not invent a linter pipeline: none is configured here.

Keep external assets referenced from the language definition. When moving them
into the unified space, adapt their real loaders and schema links so the new
location is authoritative. An unused path property does not register a snippet
or completion mapping. Avoid duplicate maintained copies or hand-edited generated
outputs. Inspect consumers and tests before changing existing module APIs.

## Discover tools through Mason

Use Mason's registry to discover candidates, then select explicitly. Never derive
tool IDs from the language name or install every search result. The included
read-only helper queries the installed Mason API and cached registries without
loading the full editor configuration or triggering installations:

```sh
nvim --headless -u NONE -i NONE -l ai/skills/introduce-language-integration/scripts/mason_candidates.lua Lua
nvim --headless -u NONE -i NONE -l ai/skills/introduce-language-integration/scripts/mason_candidates.lua 'C++' DAP
nvim --headless -u NONE -i NONE -l ai/skills/introduce-language-integration/scripts/mason_candidates.lua --languages
```

Use exact Mason language labels (case-insensitive); `--languages` lists them.
The helper reports cached availability, installation status, executable names,
categories, and any `neovim.lspconfig` metadata. Missing metadata is not evidence
of missing LSP support. An empty/unavailable/stale registry is not proof that
Mason lacks a tool. Refresh with `:MasonUpdate` or the installed asynchronous
`mason-registry.refresh(callback)` API and repeat discovery before concluding
that no package exists. Do not add refresh/network work to every buffer event.

Inspect matching specs' `languages`, `categories` (`LSP`, `Formatter`, `DAP`,
`Linter`), `bin`, platform targets, and upstream documentation. Multi-language
tools and general adapters may require an additional package-name search. Check
the installed Conform definitions, nvim-lspconfig configs, and DAP integration
docs to map package IDs to consumer IDs. No mason-lspconfig or mason-nvim-dap
bridge is configured here; do not assume either API is available.

Prefer a suitable Mason package for new installable tools. Preserve deliberate
external providers such as Forge, rustup, project virtualenvs, and Metals when
migrating existing definitions. Mark external tools with a command/check and an
actionable prerequisite. Mason does not provide parser node rules, snippets,
TreeSJ presets, test adapters, or automatic DAP configuration.

Derive the selected Mason package set from definitions. Ensure Mason is actually
initialized with `data/mason` before using it: `configs/mason.lua` exists but is
not explicitly required by `configs/init.lua` in the reviewed configuration.
Make any auto-install implementation asynchronous, deduplicated and idempotent;
honor existing installations and in-progress installs, report failures, and use
bounded retry behavior. Install selected tools, not all candidates. Missing
tools must not crash startup or disable unrelated languages. Register configs
before enabling clients; after async installation, attach eligible open buffers
without duplicating specialist-owned clients. Preserve user-disabled buffers.

Primary references, to verify against the installed versions when needed:
[Mason API](https://github.com/mason-org/mason.nvim/blob/main/doc/mason.txt),
[registry package format](https://github.com/mason-org/mason-registry/blob/main/CONTRIBUTING.md).

## Preserve runtime behavior

- Use `vim.lsp.config` / `vim.lsp.enable`, retaining buffer guards. Assign one
  lifecycle owner to each server; Rust, Scala and Java need specific attention.
  Do not replace native completion with Blink or add Blink capabilities.
- Preserve project-root and interpreter selection, delayed setup, shared DAP
  adapters, `node` / `pwa-node` compatibility, and the `envFile` listener.
  New or migrated DAP configurations must omit `console` and include
  `cwd = "${workspaceFolder}"`. Check specialist-generated defaults too.
- Preserve manual Python setup and opt-in Metals behavior unless the request
  changes it. Do not trigger Python's existing pip side effect on registry load.
- Reconcile declared parsers with the persisted Tree-sitter manifest, retaining
  user-added entries and dependency ordering. Changing `wanted` alone has no
  effect after the manifest exists. Retain failure handling and lazy retry.
- Native context mappings use actual grammar nodes and retain the neutral
  fallback for comments, strings, incomplete syntax, and ordinary call arguments.
  Basic LSP completion must work without a grammar-specific ranking mapping.
- LuaSnip collection loading and native LSP snippet expansion are separate paths.
  Verify both where applicable; do not claim that loading a collection inserts
  its snippets into the native completion menu.
- Disable plugin-created default maps when introducing repository-owned bindings;
  define bindings via `local map = require "mappings.map"`. Existing direct
  bindings are migration findings, not examples to copy.
- Retain big-file/review-buffer suppression and buffer-local behavior. Do not
  collapse the different current size thresholds as part of language migration.
- Do not manually edit `lazy-lock.json`, installed plugins, or Mason registry data.

## Completion conditions

Prove that a language definition is consumed by every applicable plugin with no
new language-specific edits to consumer lists. For an initial consolidation,
compare before/after derived settings for existing languages and verify shared
packages/adapters are registered once. Check filetype aliases explicitly.

Use focused isolated headless checks for registry outputs and missing-tool
handling, then open a representative project file to verify actual attachment,
formatter selection, completion/snippet expansion, parser queries, split/join,
sibling swap and available debug/test integration. A successful `require` alone
does not prove support. Distinguish configured, installed, and exercised support.
For completion mapping changes, use the existing suites listed in the map.
Test async installer paths with fakes where possible; avoid running the normal
startup merely to inspect settings, since it can install parsers.

Report the single place to edit for the next language, capability coverage,
external prerequisites/unsupported features, checks performed and any unverified
runtime behavior. Stop when requested integration and preservation checks pass;
do not expand into plugin upgrades or unrelated editor cleanup.
