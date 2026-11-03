# Spec Delta

## Purpose

Defines the filesystem tree actions and canonical keys that Neo-tree and Ranger both follow, so the same key performs the same action in either viewer.

## ADDED Requirements

### Requirement: Shared keymap
Neo-tree and Ranger SHALL bind every shared action to the same canonical key. A shared key MUST NOT perform a different action on the other host.

#### Scenario: Matching keys
- **WHEN** the user presses a shared canonical key in either Neo-tree's filesystem tree or Ranger
- **THEN** both hosts run the same action from the shared map (`j`, `k`, `h`, `l`, Enter, `P`, `a`, `A`, `r`, `d`, `T`, `c`, `x`, `p`, `y`, `f`, `F`, `oo`, `O`, `e`, `m`, `q`, `?`, Esc)

#### Scenario: Removed Ranger aliases that change meaning
- **WHEN** Ranger starts with this standard applied
- **THEN** `dd` is not trash, `L` is not a distinct action from `oo`, and `<A-,>` / `<A-.>` do not move Ranger tabs

### Requirement: Move the selection
The viewer SHALL move the selection one entry down on `j` and one entry up on `k`, without opening the entry.

#### Scenario: Move down
- **WHEN** the user presses `j` on an entry that has a next sibling
- **THEN** the selection moves to the next sibling and the entry is not opened

#### Scenario: Move up
- **WHEN** the user presses `k` on an entry that has a previous sibling
- **THEN** the selection moves to the previous sibling and the entry is not opened

### Requirement: Descend or open
`l` and Enter SHALL descend into a directory or open a file. On a directory with exactly one child, and that child is a directory, the action SHALL repeat until that condition is false.

#### Scenario: Open a file
- **WHEN** the user presses `l` or Enter on a file
- **THEN** the file opens in the host editor and the tree remains available

#### Scenario: Expand a directory in Neo-tree
- **WHEN** the user presses `l` or Enter on a collapsed Neo-tree directory that has more than one child, or whose only child is a file
- **THEN** that directory expands, its first child is selected, and the tree root stays unchanged

#### Scenario: Enter a directory in Ranger
- **WHEN** the user presses `l` or Enter on a Ranger directory that has more than one child, or whose only child is a file
- **THEN** that directory becomes the current directory and its first child is selected

#### Scenario: Skip a single-child directory chain
- **WHEN** the user presses `l` or Enter on a directory whose only child is a directory
- **THEN** the viewer continues through each single-child directory and stops on the first directory that is empty, has several children, or has a single file child

### Requirement: Ascend
`h` SHALL move toward the parent. Neo-tree SHALL collapse an expanded directory before jumping to its parent. Ranger SHALL move to the parent column.

#### Scenario: Collapse an expanded directory
- **WHEN** the user presses `h` on an expanded directory in Neo-tree
- **THEN** that directory collapses and the selection stays on it

#### Scenario: Move to the parent
- **WHEN** the user presses `h` on a file, or on a directory that is not expanded
- **THEN** the selection moves to the parent directory

### Requirement: Preview the selection
`P` SHALL toggle a preview of the selected file. Esc SHALL close an open preview.

#### Scenario: Toggle preview
- **WHEN** the user presses `P` on a file
- **THEN** a preview of that file appears, and pressing `P` again hides it

#### Scenario: Preview is not available for a directory
- **WHEN** the user presses `P` on a directory
- **THEN** the viewer does not open a file preview

### Requirement: Create an entry
`a` SHALL prompt for a name and create that entry under the current directory. A name ending in `/` SHALL create a directory. Any other name SHALL create a file. The new entry SHALL become the selection.

#### Scenario: Create a file
- **WHEN** the user presses `a` and submits `notes.txt`
- **THEN** an empty file named `notes.txt` is created in the current directory and selected

#### Scenario: Create a nested directory by trailing slash
- **WHEN** the user presses `a` and submits `src/lib/`
- **THEN** the directory `src/lib` is created and selected

#### Scenario: Cancel create
- **WHEN** the user presses `a` and cancels the prompt
- **THEN** no file or directory is created

### Requirement: Create a directory
`A` SHALL prompt for a directory name, create that directory under the current directory, and select it.

#### Scenario: Create a directory
- **WHEN** the user presses `A` and submits `assets`
- **THEN** the directory `assets` is created and selected

### Requirement: Rename the selection
`r` SHALL prompt for a new name, rename the selection, and leave the selection on the renamed entry.

#### Scenario: Rename a file
- **WHEN** the user presses `r` on `a.txt` and submits `b.txt`
- **THEN** `a.txt` is renamed to `b.txt` and `b.txt` is selected

#### Scenario: Cancel rename
- **WHEN** the user presses `r` and cancels the prompt
- **THEN** the name is unchanged

### Requirement: Delete the selection
`d` SHALL ask for confirmation and then permanently delete the selection. A single `d` SHALL start this action without waiting for a second `d`.

#### Scenario: Confirm delete
- **WHEN** the user presses `d` and confirms
- **THEN** the selected file or directory is permanently removed

#### Scenario: Decline delete
- **WHEN** the user presses `d` and declines
- **THEN** the selected entry remains

### Requirement: Trash the selection
`T` SHALL move the selection to the system trash and report that path. `T` MUST NOT permanently delete the entry.

#### Scenario: Trash a file
- **WHEN** the user presses `T` on a file
- **THEN** the file leaves the directory, is in the system trash, and the viewer reports that path

### Requirement: Ranger marks
Ranger Space SHALL toggle a mark on the current entry. Neo-tree Space SHALL do nothing.

#### Scenario: Toggle a Ranger mark
- **WHEN** the user presses Space on an unmarked entry in Ranger
- **THEN** that entry becomes marked, and pressing Space again clears the mark

#### Scenario: Neo-tree Space is unused
- **WHEN** the user presses Space in the Neo-tree filesystem tree
- **THEN** the selection, expansion, and clipboard stay unchanged

### Requirement: Clipboard copy, cut, and paste
`c` SHALL mark the current entry for copy. `x` SHALL mark it for cut. `p` SHALL paste the marked entries into the current directory and select the pasted entries. Paste SHALL refuse when the clipboard is empty. In Ranger, a non-empty mark set SHALL replace the current entry for `c`, `x`, `d`, and `T`.

#### Scenario: Copy and paste
- **WHEN** the user presses `c` on a file and `p` in another directory
- **THEN** the file exists in both directories and the pasted file is selected

#### Scenario: Cut and paste
- **WHEN** the user presses `x` on a file and `p` in another directory
- **THEN** the file exists only in the destination directory and is selected there

#### Scenario: Paste with an empty clipboard
- **WHEN** the user presses `p` and nothing is marked for copy or cut
- **THEN** the viewer reports that there is nothing to paste and creates no entry

### Requirement: Copy a path
`y` SHALL offer these path forms and copy the chosen one to the system clipboard: path relative to the working directory, absolute path, path relative to home, filename, filename without extension, and extension.

#### Scenario: Copy the absolute path
- **WHEN** the user presses `y` and chooses the absolute path
- **THEN** the system clipboard contains the absolute path of the selection and the viewer reports that text

#### Scenario: Cancel path copy
- **WHEN** the user presses `y` and cancels the choice
- **THEN** the system clipboard is unchanged

### Requirement: Find files and search contents
`f` SHALL search file names under the scope directory. `F` SHALL search file contents under the scope directory. The scope directory SHALL be the selection when it is a directory, and the parent directory when the selection is a file.

#### Scenario: Find files in a directory
- **WHEN** the user presses `f` on a directory
- **THEN** a file-name search opens, limited to that directory

#### Scenario: Search contents from a file
- **WHEN** the user presses `F` on a file
- **THEN** a content search opens, limited to that file's parent directory

### Requirement: Open in a new terminal tab
`oo` SHALL open the selection in a new Kitty tab in the same OS window. A directory SHALL be that tab's working directory. A file SHALL use its parent directory as the working directory.

#### Scenario: Open a directory in a new tab
- **WHEN** the user presses `oo` on a directory
- **THEN** a new Kitty tab opens with that directory as its working directory

#### Scenario: Open a file's parent in a new tab
- **WHEN** the user presses `oo` on a file
- **THEN** a new Kitty tab opens with that file's parent directory as its working directory

#### Scenario: Several items are selected
- **WHEN** the user presses `oo` while more than one item is marked
- **THEN** the viewer reports that exactly one item must be selected and opens no tab

### Requirement: Open in the system file manager
`O` SHALL reveal the selection in the system file manager. A directory SHALL open directly. A file SHALL be selected in its parent folder.

#### Scenario: Reveal a file
- **WHEN** the user presses `O` on a file
- **THEN** the system file manager opens with that file selected in its parent folder

### Requirement: Make executable and edit mode
`e` SHALL set the user-executable bit on a file and SHALL refuse a directory. `m` SHALL prompt with the selection's current mode and apply the submitted mode.

#### Scenario: Make a file executable
- **WHEN** the user presses `e` on a non-executable file
- **THEN** the file gains the user-executable bit and the viewer reports the file name

#### Scenario: Refuse a directory
- **WHEN** the user presses `e` on a directory
- **THEN** the mode is unchanged and the viewer reports that a file is required

#### Scenario: Change mode
- **WHEN** the user presses `m` and submits a valid mode
- **THEN** the selection's mode changes to the submitted mode

#### Scenario: Cancel mode edit
- **WHEN** the user presses `m` and cancels the prompt
- **THEN** the mode is unchanged

### Requirement: Close, help, and cancel
`q` SHALL close the viewer. `?` SHALL show the viewer's key help. Esc SHALL close a preview when one is open, clear marked entries, and clear the copy/cut clipboard.

#### Scenario: Close the viewer
- **WHEN** the user presses `q`
- **THEN** the file-tree viewer closes

#### Scenario: Show help
- **WHEN** the user presses `?`
- **THEN** the viewer shows help that includes the canonical keys

#### Scenario: Clear marks and clipboard
- **WHEN** entries are marked or a copy/cut clipboard is set and the user presses Esc
- **THEN** the marks are cleared, the clipboard is empty, and no file is copied or moved

### Requirement: Visible and hidden names
Both hosts SHALL show dotfiles and gitignored files by default. Both hosts SHALL hide entries named `.git`, `.DS_Store`, and `thumbs.db`.

#### Scenario: Dotfiles stay visible
- **WHEN** the user opens a directory that contains `.bashrc` and a gitignored file
- **THEN** both entries are visible without a separate toggle

#### Scenario: VCS directory stays hidden
- **WHEN** the user opens a directory that contains `.git`
- **THEN** `.git` is not listed

### Requirement: Refresh the listing
Both hosts SHALL reload the current directory from disk. Neo-tree SHALL do this on `<leader>rr`. Ranger SHALL do this on `R`, because Ranger has no leader prefix.

#### Scenario: Refresh in Neo-tree
- **WHEN** a file is created outside Neo-tree and the user presses `<leader>rr` in the filesystem tree
- **THEN** the listing includes that file

#### Scenario: Refresh in Ranger
- **WHEN** a file is created outside Ranger and the user presses `R`
- **THEN** the listing includes that file and no replace UI opens

### Requirement: Tree-shape controls stay on Neo-tree
Neo-tree SHALL collapse every node on `w`, expand every nested node of the selection on `W`, and collapse every nested node of the selection on `C`. `<A-,>` and `<A-.>` SHALL switch to the previous and next Neo-tree source. Ranger MUST NOT bind those keys to a different action.

#### Scenario: Collapse the whole tree
- **WHEN** the user presses `w` in Neo-tree while directories are expanded
- **THEN** every directory in the tree collapses

#### Scenario: Switch source
- **WHEN** the user presses `<A-.>` in Neo-tree
- **THEN** the next Neo-tree source is shown

#### Scenario: Ranger does not reuse tree-shape keys
- **WHEN** the user presses `w`, `W`, `C`, `<A-,>`, or `<A-.>` in Ranger
- **THEN** Ranger does not move tabs, change sort, or run a different file action

### Requirement: Neovim-only file actions
In the Neo-tree filesystem tree, `s` SHALL stage the selection, `u` SHALL unstage it, `i` SHALL toggle a `.gitignore` entry for it, `R` SHALL open replace scoped to the scope directory, `<A-i>` SHALL show file details, `<leader>tn` SHALL open a terminal in the scope directory, and `S` SHALL open the file in a split. Ranger MUST NOT bind `s`, `u`, `i`, `<A-i>`, or `S` to a different action. Ranger `R` is refresh, not replace.

#### Scenario: Toggle gitignore
- **WHEN** the user presses `i` on a file inside the working directory that is not ignored
- **THEN** that relative path is added to the working directory's `.gitignore`

#### Scenario: Gitignore outside the working directory
- **WHEN** the user presses `i` on a path outside the working directory
- **THEN** `.gitignore` is unchanged and the viewer reports that the path is outside the working directory

#### Scenario: Replace in a directory
- **WHEN** the user presses `R` on a directory in Neo-tree
- **THEN** a replace UI opens limited to that directory

#### Scenario: Ranger leaves Neovim keys unused
- **WHEN** the user presses `s`, `u`, `i`, or `S` in Ranger
- **THEN** Ranger does not sort, open a shell, inspect, or run another action on that key

### Requirement: Ranger archive commands stay off the shared map
Ranger MAY keep archive compress and extract on the key sequences `zip` and `unzip`. Those sequences MUST NOT replace a shared canonical key.

#### Scenario: Compress a selection
- **WHEN** the user runs the `zip` sequence in Ranger with one or more entries marked and submits an archive name
- **THEN** a zip archive of those entries is created in the current directory

#### Scenario: Extract into a new directory
- **WHEN** the user runs the `unzip` sequence on an archive whose destination directory does not exist
- **THEN** the archive is extracted into a new directory named after the archive, not into the current directory itself

#### Scenario: Shared keys stay stable
- **WHEN** the user presses a shared canonical key after the archive commands are configured
- **THEN** that key still performs its shared action
