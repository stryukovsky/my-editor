## ADDED Requirements

### Requirement: Include eligible untracked files

Filesystem Git-change navigation SHALL include untracked files when
`consider_untracked_as_git_change` is enabled, alongside existing tracked-change
targets. It SHALL exclude ignored files and ordinary directory-only status entries.

#### Scenario: Untracked file in an existing folder
- **WHEN** an existing folder contains both a modified tracked file and an untracked file
- **THEN** both files are reachable with `]g` and `[g`

#### Scenario: Entirely untracked folder
- **WHEN** an unexpanded, wholly untracked folder contains files at multiple depths
- **THEN** every non-ignored file is individually reachable without manually expanding the folder first
- **AND** navigation reveals the selected file's ancestors

#### Scenario: Untracked navigation disabled
- **WHEN** `consider_untracked_as_git_change` is disabled
- **THEN** untracked files are excluded and tracked changes remain reachable

### Requirement: Navigate in depth-first tree order

`]g` SHALL select the next eligible file in depth-first filesystem tree display
order, honoring configured sibling sorting even for collapsed descendants.
`[g` SHALL use the exact reverse order. Path depth SHALL NOT independently give
shallower files priority. The current selection, including a directory or clean
file, SHALL determine the starting position in that same tree order.

#### Scenario: Nested changes precede a later root file
- **WHEN** the default directory-first tree contains changed files `a/deep/one.txt`, `a/two.txt`, and `z.txt`
- **THEN** successive forward targets are `a/deep/one.txt`, `a/two.txt`, and `z.txt`
- **AND** reverse navigation visits those targets in reverse order

#### Scenario: Collapsed subtree
- **WHEN** a changed file's ancestors are collapsed
- **THEN** that file retains the position it would have in the expanded tree

#### Scenario: Start from a directory or clean file
- **WHEN** the current selection is not an eligible changed file
- **THEN** navigation chooses the nearest eligible file in the requested direction according to tree order

### Requirement: Preserve scope and stable edge behavior

Navigation SHALL remain inside the displayed filesystem root, wrap at either
end, and leave focus unchanged when no eligible file exists. Refreshed Git status
SHALL update candidates without requiring manual folder expansion.

#### Scenario: Wraparound
- **WHEN** navigation reaches the final eligible file in either direction
- **THEN** the next invocation wraps to the opposite end of the same ordered list

#### Scenario: Empty candidate set
- **WHEN** there are no eligible files, including when status contains only ignored or unavailable paths
- **THEN** navigation leaves focus unchanged without error

#### Scenario: Root scope and refresh
- **WHEN** the tree is rooted at a repository subdirectory and Git status refreshes after files are created or removed
- **THEN** navigation uses the updated eligible files under that root and excludes sibling directories outside it

### Requirement: Navigate changed submodule gitlinks

Navigation SHALL include changed submodule paths reported directly by Git as
leaf targets, even though their filesystem type is directory. It SHALL preserve
the existing tree ordering and exclude ordinary bubbled directory statuses.

#### Scenario: Changed checkout or staged commit pin
- **WHEN** a submodule checkout differs from the recorded commit, or its new commit is staged in the superproject
- **THEN** both forward and reverse navigation can select the submodule itself
- **AND** subsequent navigation continues to the next eligible target

#### Scenario: Dirty and clean submodules
- **WHEN** Git reports tracked dirtiness in a submodule
- **THEN** its path is an eligible target
- **WHEN** Git reports no change for that submodule
- **THEN** its path is excluded
