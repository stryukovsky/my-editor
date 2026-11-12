> Implementation revision: the operator subsequently approved replacing
> `nvim-lsp-file-operations` with the fork's native
> `filesystem/lib/lsp_rename.lua`. Its `methods(client, path)` and `hooks(clients)`
> own static filter matching and protocol dispatch, with a 10000 ms timeout and
> visible best-effort error warnings. Config retains client selection and
> default-No unsupported-client confirmations. Both patches and the dependency
> are removed. Plugin-specific decisions below describe the superseded design;
> see verification.md for the current implementation and proof.

## Context

See proposal.md for scope. The configured tree is `stryukovsky/neo-tree.nvim`,
branch `option-consider-untracked-as-git-change`, installed under
`data/lazy/neo-tree.nvim`. Filesystem `r` and `<leader>rn` currently select
`rename`; document-symbol `r` is a separate symbol rename action.

The existing filesystem command delegates to common commands and then
`filesystem/lib/fs_actions.lua:rename_node`. That function owns input completion,
path resolution, cancellation, collision/no-op checks, asynchronous disk rename,
open-buffer updates, events, and the refresh callback. Preserve that ownership.

Upstream `nvim-lsp-file-operations.setup()` creates automatic integrations based
on loaded tree modules. Its direct `will_rename` and `did_rename` APIs instead
accept `{ old_name = source, new_name = destination }`. Those APIs perform
capability/filter matching and workspace-edit handling without subscriptions.

## Decisions

### Explicit invocation through Neo-tree configuration

In `lua/configs/neotree.lua`, add a filesystem command named `lsp_rename` and map
only filesystem `r` to it. Its helper lives in
`lua/integrations/neotree_lsp_rename.lua` and delegates to the fork's existing
filesystem rename command with per-invocation callbacks. Do not replace the
built-in command named `rename`, monkey-patch exported functions, subscribe to
Neo-tree events, or use temporary global subscribers.

The edited tasks are authoritative: before prompting for the destination, gather
initialized, running clients connected to the selected path's project through
their root, workspace folders, or attached buffers. With none, invoke ordinary
rename without loading the LSP plugin. With one, use it directly. With several,
show a Telescope multi-select picker; Tab toggles recipients and Enter confirms
the selection (or the current entry when none are marked). Cancel aborts the
operation. Client IDs distinguish multiple instances of the same server. Include
connected clients even if they advertise no rename method; the protocol filters
then correctly skip unsupported operations.

The upstream direct callbacks discover all active clients. A small tracked patch
adds an optional `clients` argument to those callbacks; omitting it preserves
upstream behavior. Pass the selected list to both rename callbacks. Do not
temporarily replace `vim.lsp.get_clients` or the plugin's discovery helper.

The minimal fork seam is an optional callback table on the filesystem rename
command, forwarded through common rename to `fs_actions.rename_node`. Existing
call signatures remain valid. Call `before_rename(source, destination)` only
after input and safety checks, immediately before the existing rename execution;
call `after_rename(source, destination)` exactly once after disk success and
buffer updates, before completing the ordinary refresh. A thrown before-hook
error reports failure and prevents disk mutation. A thrown after-hook error is
reported without suppressing the successful filesystem refresh.

The configured hooks call `lfo.will_rename` and `lfo.did_rename`. These are the
plugin's rename protocol implementation; Neo-tree still owns disk mutation.
Calling `lfo.rename()` directly would duplicate buffer ownership, bypass tree
safety, and potentially reload modified buffers; avoid that alternative.
Passing hooks per invocation also keeps `<leader>rn`, other sources, moves,
and ordinary rename callers outside the integration.

### Library initialization without automatic integrations

Declare the plugin with plenary available and without `opts`, a setup callback,
or `cmd = "LFO"`. Initialize its library configuration explicitly from the
integration helper using `config.get_defaults()` plus `config.set()` (deep-copy
defaults first), and initialize its logger with `log.setup()`. Set
`auto_save = false`, enable only `willRenameFiles` and `didRenameFiles`, and use
the upstream bounded timeout of 10000 ms. Never call `setup()`; it installs the
automatic integrations that this change intentionally excludes.

The upstream runtime file separately defines the global `:LFO` command. Suppress
that file with its existing `loaded_lsp_file_operations` startup guard before
lazy.nvim sources it. This flag only prevents command registration; it is not
a global rename hook or mapping. Keep this suppression in the dependency
declaration, with all behavioral wiring in Neo-tree's explicit command config.
Do not add a second plugin fork or manual runtime-path loader for this purpose.

There is no tree/plugin discovery step, so no required ordering between loading
Neo-tree and this library. Normal dependency availability and LSP initialization
still matter. Lazy pin updates must use the package manager, not hand edits.

### Explicit server negotiation

Before the existing enable loop, merge only rename capabilities into the named
`ts_ls`, `basedpyright`, `lua_ls`, and `jdtls` configurations, preserving completion
and other capabilities. Configure rust-analyzer through rustaceanvim's existing
server configuration before its startup. Advertise `willRename` for TypeScript,
Python, Rust, and Java; `didRename` for Lua. Do not set `vim.lsp.config("*", ...)`,
modify protocol capability factories, or change lspconfig defaults. No extra
capabilities are required for servers without matching methods.

These startup capabilities advertise client ability; runtime server capability
filters remain authoritative. Do not hardcode filename extensions or treat
symbol `renameProvider` as evidence for file operations. The explicit recipient
list does not require attachment to the Neo-tree scratch buffer. Verify
multiple-workspace behavior and filter matching without monkey-patching client
enumeration in the implementation.

### Failure behavior and verification

Cancellation, unchanged names, and existing destinations exit before LSP work.
No matching server is an ordinary filesystem rename. Upstream pre-rename
requests are synchronous and best-effort: null results, server errors, or
timeouts do not reliably propagate an abort result. Retain that behavior and
do not claim transactional rollback. Disk failure must skip `did_rename` and
report the failure. Returned workspace edits remain unsaved as configured.

Use disposable headless fixtures during apply, not a new repository test
framework. Prove before/edit/disk/after ordering, one dispatch per client,
capability filters, no-server fallback, cancellation, collision, directory and
modified-buffer preservation, disk failure, and repeated opening without
subscribers. Inspect actual buffer-local `r` and unchanged `<leader>rn` and
document-symbol mappings. Use `mappings.map` for any new direct bindings; the
Neo-tree key remains declared in its own configuration table.

## Risks / Trade-offs

- A server's advertised support does not guarantee complete refactoring → retain
  per-server limitations in server-support.md and verify a real import example.
- Workspace edits may already exist when disk rename fails → report failure;
  do not advertise automatic rollback or silently save edited files.
- The plugin's direct configuration API and runtime guard are lower-level seams
  → verify them against the revision installed during apply and pin through lazy.
- This requires a small compatible fork change → prepare/review the fork diff
  separately and retain its existing dirty work; never replace it with upstream.
- A synchronous request can wait up to the timeout per matching client → use the
  existing timeout and avoid unnecessary dispatch through capability filters.

## Migration Plan

Apply the fork seam first, then add the dependency/helper and the explicit config
binding. Negotiate selected server capabilities before enabling clients. Record
the fork revision or a reviewable patch for reproducibility and update locks
through lazy.nvim only. For rollback, restore filesystem `r = "rename"` and
remove the selected capabilities/helper/dependency. The optional fork callbacks
remain inert for existing callers. No data migration is involved.

Both extensions are stored in `patches/<plugin-name>.patch` and applied by the
plugin's lazy.nvim build callback. Application is idempotent and checks conflicts
before modifying a checkout. The installed fork was clean before this change;
its base revision and the plugin revision are pinned by lazy.nvim.
