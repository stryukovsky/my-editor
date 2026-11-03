## ADDED Requirements

### Requirement: Remote picker uses the pretty picker public API

The pretty picker module SHALL expose `show_remotes(opts)` and the Git remotes mapping SHALL call it. The facade SHALL forward cwd and Neo-tree state without changing remote rows, action ordering, shortcuts, confirmations, cancellation, or URL handling. The existing internal `.open(opts)` entry point SHALL remain available.

#### Scenario: Open remotes from a Neo-tree Git action
- **WHEN** the remotes mapping is invoked with a Neo-tree state
- **THEN** `show_remotes` forwards that state and the picker resolves the same repository as before

#### Scenario: Existing remote interaction remains available
- **WHEN** the user selects a remote row
- **THEN** its direct action keys still work and Enter opens its existing action menu

### Requirement: Enter opens the selected row's actions

The standard pretty branch and commit pickers SHALL open an action menu for the focused row when Enter is pressed in Normal or Insert mode. Opening the menu SHALL NOT execute a Git mutation. Empty selections SHALL NOT open a menu or execute an action. The menu SHALL identify the selected branch or commit.

#### Scenario: Inspect branch actions
- **WHEN** the user presses Enter on branch `feature/demo`
- **THEN** an action menu for `feature/demo` opens and the current branch remains unchanged

#### Scenario: Inspect commit actions from Insert mode
- **WHEN** the user presses Enter while filtering commits in Insert mode
- **THEN** the focused commit's action menu opens without checking out a commit

### Requirement: The former Enter action is first and initially selected

The branch menu SHALL list Switch branch first. The commit menu SHALL list Checkout commit (detached HEAD) first. The action selector SHALL open in Normal mode with the first action focused. With no intervening navigation or input, Enter followed by Enter SHALL invoke the same behavior as the former single Enter, including all existing checks and no-op cases.

#### Scenario: Switch with two Enters
- **WHEN** the user presses Enter twice on a local branch
- **THEN** the picker invokes its existing switch behavior for that branch

#### Scenario: Switch to a remote-tracking branch
- **WHEN** the user presses Enter twice on a remote-tracking branch
- **THEN** the existing local-branch lookup and tracking-branch creation behavior is retained

#### Scenario: Checkout with two Enters
- **WHEN** the user presses Enter twice on a commit other than HEAD
- **THEN** the picker checks out that commit using the existing detached-HEAD behavior

### Requirement: Menus expose existing actions

The branch menu SHALL expose switch, delete, merge, rename, rebase, and yank-name actions. The commit menu SHALL expose checkout, rename HEAD, undo HEAD keeping changes staged, undo HEAD and stash, and yank-SHA actions.

#### Scenario: Discover commit actions
- **WHEN** the user opens the commit action menu
- **THEN** checkout, HEAD rename, both undo forms, and yank are listed with labels explaining HEAD restrictions

### Requirement: Direct shortcuts remain available

Existing direct Normal-mode shortcuts SHALL remain available on each main list and use the same action implementations as menu choices. Prompt hints SHALL describe Enter as actions and retain direct shortcut hints. Action shortcuts SHALL NOT consume ordinary Insert-mode prompt text.

#### Scenario: Direct branch merge
- **WHEN** the user presses `m` on the branch list
- **THEN** the existing merge flow starts directly without first opening the action menu

#### Scenario: Commit action aliases remain
- **WHEN** the user presses `a` or `r` on the commit list
- **THEN** the existing HEAD rename flow runs

#### Scenario: Direct yank stays on the list
- **WHEN** the user presses `y` on a branch or commit list
- **THEN** existing register contents and multi-selection yank semantics are preserved and the list stays open

### Requirement: Action context survives the menu transition

Actions SHALL retain the selected entry and repository after the original prompt closes. Branch deletion SHALL preserve its existing multi-selection behavior; other mutations SHALL retain their existing focused-row scope.

#### Scenario: Repository stays fixed
- **WHEN** an action menu was opened from a picker scoped to repository A and the editor cwd changes before an action is chosen
- **THEN** the action still targets the captured selection in repository A

#### Scenario: Delete multiple branches through the menu
- **WHEN** several branches are selected and Delete branch is chosen from the action menu
- **THEN** the same selected branches and confirmation behavior as direct `d` are used

### Requirement: Existing action safeguards remain

Both routes SHALL preserve confirmation dialogs, local-only branch rename, merge tracking warnings, Git error reporting, HEAD-only commit mutations, staged-change protection, and undo/stash recovery. Checks SHALL run at action execution rather than rely solely on state observed when opening the menu.

#### Scenario: Older commit cannot be undone
- **WHEN** the user chooses an undo action on a commit that is not HEAD
- **THEN** the existing HEAD-only warning is shown and Git history is unchanged

#### Scenario: HEAD changes while the menu is open
- **WHEN** HEAD changes after the action menu opens and the user chooses Rename HEAD for the previously selected commit
- **THEN** the action revalidates the selection and does not amend a different commit

### Requirement: Cancellation restores list context

Canceling the action menu SHALL execute no mutation or yank and SHALL reopen the originating list with its repository, query, selected row when available, and original picker options. Menu-based yank SHALL preserve existing register and multi-selection semantics and return to that list. Missing selections SHALL be handled safely without acting on an unintended replacement row.

#### Scenario: Cancel a filtered commit action menu
- **WHEN** the user opens actions from a filtered commit picker scoped to a ref and cancels
- **THEN** the same ref, limit, query, preview, and selected commit are restored when available

### Requirement: Custom picker consumers keep their Enter semantics

Caller-supplied `attach_mappings` SHALL retain control over selection and shortcuts. The default action menu SHALL NOT replace Enter in custom branch or commit workflows, including MiniDiff history/review. Previewer and title overrides SHALL remain supported.

#### Scenario: MiniDiff branch selection
- **WHEN** the user presses Enter on a branch in MiniDiff history
- **THEN** the existing commit-selection workflow opens directly without a branch action menu or switch

#### Scenario: MiniDiff commit review
- **WHEN** the user presses Enter on selected commits in MiniDiff history
- **THEN** the existing merged review starts directly without a commit action menu or checkout
