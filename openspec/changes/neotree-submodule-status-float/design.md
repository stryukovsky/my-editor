## Decisions

Identify exact `160000` entries with NUL-delimited `ls-files --stage` and
`ls-tree HEAD`, using literal pathspecs. This also identifies added, deleted,
and conflicted gitlinks without treating every directory as a submodule.
Read current status on each open, independently of the tree's selected section.
Collect committed parent HEAD and index separately, but display only the child
HEAD and committed parent pin as eight-character hashes. Highlight a changed
child hash red; staging alone does not change the committed pin. Keep the summary
to three lines and label unavailable checkout hashes honestly. The title identifies
commit changes, uncommitted contents, or both. Check that the child repository has an empty Git prefix before
reading its HEAD, preventing an uninitialized directory from resolving parent HEAD.

The source's `open` command handles inspection and falls back to common opening
for non-submodules. The config's existing `go_deep` delegates leaf opening to it.
Use a centered, focused scratch float with `bufhidden=wipe`, readonly content,
and `DiagnosticError` highlighting. WinLeave, BufLeave, WinClosed and FocusLost
schedule idempotent window/buffer cleanup and delete their autocmd group.

Git reads are local and bounded by a per-command three-second timeout. No staging,
checkout, commit, or other repository mutation is performed by the inspector.

Bind `q` and Escape through `mappings.map` to the same idempotent cleanup function.
The read-only three-line summary replaces the earlier verbose staging/index view.
