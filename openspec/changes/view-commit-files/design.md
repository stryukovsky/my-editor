# Design

The shared action menu captures the selected SHA and repository before closing Telescope. The new handler uses that context to query affected paths with a NUL-delimited Git tree diff. Root commits compare against the empty tree. Merge commits use the union of paths changed relative to their parents. A rename contributes both paths, so either can appear if it currently exists as a readable file.

A dedicated Trouble source receives absolute file paths as view options. Trouble uses its normal file jump to open an existing buffer or load the working-tree file. Reopening the action replaces the previous commit's Trouble view.
