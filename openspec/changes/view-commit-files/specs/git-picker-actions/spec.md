## ADDED Requirements

### Requirement: View the selected commit's affected files

The standard pretty commit picker SHALL offer **View affected files (v)** in its action menu and bind `v` on the main list in Normal mode. Either route SHALL open a focused Trouble list for the selected commit in the captured repository. The list SHALL include each affected path that currently resolves to a readable file. Selecting a row SHALL open the ordinary working-tree buffer for that path.

#### Scenario: Browse an older commit
- **WHEN** the user invokes the action on an older commit
- **THEN** the list contains the readable working-tree files affected by that commit
- **AND** opening an entry displays its current contents with the current checkout intact

#### Scenario: An affected file no longer exists
- **WHEN** a path affected by the selected commit is absent from the working tree
- **THEN** Trouble omits the path

#### Scenario: No affected files are available
- **WHEN** the selected commit has no affected paths that are readable files
- **THEN** the picker reports that no affected files are available in the current worktree and keeps or restores the commit list
