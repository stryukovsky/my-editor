# Design

## Context

See `proposal.md` for motivation and `specs/markdown-preview-navigation/spec.md` for the behavior contract.

The Neovim config selects `stryukovsky/render-markdown.nvim` on `fix/anti-conceal-in-wrapped-table`. The installed fork's `core/preview.lua` replaces the source in the same window, manages optional simultaneous source windows, refreshes on text changes, and synchronizes on cursor events. Its `sync/init.lua` builds wrapped text and table output together with navigation blocks; `sync/paragraph.lua` retains per-line maps and packed row pairs. Tables use proportional mapping. Open, close, refresh, and cursor callbacks all depend on these mappings.

The fork already parses ATX and Setext headings for its built-in document-symbol provider in `integ/lsp.lua`. `tests/preview_spec.lua` covers preview lifecycle, cursor follow, and symbols, while `tests/unit/sync_spec.lua` asserts the old maps. The plugin checkout is a separate Git repository inside ignored config `data/`; the current chat workspace is Neovim core, which is not an implementation target.

## Goals / Non-Goals

**Goals:** One authoritative source outline, explicit source/preview heading pairs, pair-local section state, and no positional navigation fallback.

**Non-Goals:** Viewport scroll binding independent of the cursor, exact cursor round trips within sections, browser-preview changes, new navigation keymaps, or redesigning document symbols and rendering.

## Decisions

### 1. Use the active cursor's preceding heading

Interpret “last reached heading” spatially: the last heading at or before the cursor, including all levels. Recompute on backward motion and jumps; do not retain the most recently visited heading in chronological history. Anchor zero denotes the preamble/document beginning.

Only a section change drives follow; ordinary cursor motion within a section does not reposition the other pane. The existing cursor events cover keyboard movement and symbol jumps without adding competing scroll events. Viewport-based sync was considered but would create a different rule when cursor and viewport identify different sections.

### 2. Extract headings from source and record output anchors during rendering

Reuse the parser traversal and level recognition in `integ/lsp.lua` where practical, without depending on an attached LSP client or changing symbol behavior. The navigation outline must include every actual heading, including headings with empty titles; the existing title-oriented symbol helper filters these, so adapt or narrowly share traversal rather than blindly consuming its result.

Create ordered records with occurrence identity, level, source row, and emitted preview row. Associate preview rows as text is generated. This is heading-only rendering metadata, not a revived source-line mapping. Never match headings by title or by independently reparsing formatted preview text: wrapping and duplicate titles make those approaches unreliable.

Keep heading syntax and multiline Setext headings intact when generating preview text. The installed Mermaid integration now keeps the preview window nowrap; retain that setting, so long headings use horizontal scrolling while prose and table formatting keep their current behavior. This prevents hard wrapping from turning a heading continuation into an apparent unrelated paragraph or losing its symbol identity.

### 3. Replace navigation state across the entire lifecycle

Store the selected heading identity per source/preview pair, even when one buffer is hidden. Cursor callbacks resolve a section, compare it with the pair's current selection, and move counterpart windows to the paired heading start at column zero only on change. Preserve the origin cursor and focus.

Use an explicit programmatic-move guard plus the already-selected identity so delayed counterpart cursor events cannot bounce back. Opening/reopening and closing deliberately apply the current anchor even if the section has not changed. Cleanup removes all outline, anchor, and event state for the affected pair.

### 4. Rebuild correspondence after edits and preserve surviving occurrences

Rebuild rendered positions and the outline together on existing text-change refreshes. Keep lightweight source heading extmarks to track occurrence positions across edits, then reconcile those marks with the new source outline; buffer changed-row information identifies removed heading ranges so a deleted heading is not reassigned to its successor. This survives title renames and insertions before repeated titles without matching by text or relying on unstable ordinal indices across revisions.

If the source is active, recompute its section from its post-edit cursor. If the preview is active, preserve its selected surviving occurrence, or select the closest surviving predecessor from the old outline when deleted. Remove abandoned marks and clear the tracking namespace on pair teardown. Row shifts from text replacement in the preview must not become navigation input during refresh.

An ordinal within a single snapshot is sufficient for lookup but insufficient as persistent edit identity. A full diff or general per-line correspondence is unnecessary for heading anchors.

### 5. Retain rendering utilities and remove obsolete mapping machinery

Keep the prose wrapper, table renderer, kinds/highlights, and existing output shape where callers need them. Delete paragraph position methods, table ratios, navigation-only block metadata, per-line maps, packed row-pair usage, and old cursor anchors once their references are migrated. Remove a shared helper only after confirming it has no other callers. Replace obsolete positional assertions with structural navigation assertions while retaining output regression coverage.

## Risks / Trade-offs

- Coarser return positions are intentional: switching back lands at the selected heading. Document this explicitly.
- Editing a heading while the preview is active can invalidate its identity. Track occurrences through source edits and test deletion, rename, duplicate titles, and insertion before selection.
- Deferred cursor events can cause reciprocal movement. Set selected state before moving peers and test the initiating cursor after event processing.
- Long and Setext headings are sensitive to hard wrapping. Preserve heading syntax and keep symbol tests alongside navigation tests.
- Heading parsing can be unavailable. Do not fall back to regex or old line sync: keep preview rendering operational, use the document-start anchor for that snapshot, and rebuild when parsing succeeds.
- Plugin edits inside ignored `data/` do not persist in the config repository. Retain implementation in the fork and update the config through its normal plugin workflow, without hand-editing `lazy-lock.json`.

## Migration Plan

No data migration is required. Implement and test in the fork checkout, retain the change in the fork's Git history through the normal review workflow, and integrate it through the config's existing plugin specification. Publishing or pushing is a separate action. Rollback restores the prior fork revision through the normal plugin workflow; no compatibility mode preserving the old synchronization is planned.
