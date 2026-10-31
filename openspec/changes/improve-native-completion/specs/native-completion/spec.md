# Spec Delta

## Purpose

Provide readable native completion whose ranking follows typed intent while retaining language-server edits, predictable acceptance, and safe fallback behavior.

## ADDED Requirements

### Requirement: Text relevance precedes kind preferences

Completion SHALL rank exact case-sensitive matches, exact case-insensitive matches, case-sensitive prefixes, case-insensitive prefixes, and other fuzzy matches in that order. Within a class, current-line identifier affinity SHALL rank before fine fuzzy relevance. Higher fuzzy relevance SHALL break affinity ties. Text relevance SHALL precede all kind, syntax, server, snippet, and deprecation preferences.

#### Scenario: Exact function beats a variable prefix
- **WHEN** the query is `print` and candidates include function `print` and variable `printOptions`
- **THEN** `print` appears first regardless of kind or server preference

#### Scenario: Exact variable beats a function prefix
- **WHEN** the query is `pri` and candidates include variable `pri` and function `print`
- **THEN** `pri` appears first

#### Scenario: Case-sensitive prefix wins within prefix matches
- **WHEN** the query is `get` and candidates include `getValue` and `GetValue`
- **THEN** `getValue` ranks above `GetValue`

#### Scenario: Better fuzzy match beats kind preference
- **WHEN** two nonprefix candidates have equal current-line affinity and different fuzzy relevance for the same base
- **THEN** the more relevant candidate appears first regardless of their kinds

### Requirement: Current-line identifiers influence relevance

Within the same typed-match class, completion SHALL favor more distinct identifier words shared with the current line outside the active replacement span. Matching SHALL use case-folded whole identifier components, excluding query components, language keywords, comments, and strings. Repetition SHALL not increase affinity. Unavailable syntax SHALL give neutral affinity.

#### Scenario: User context favors creating a user
- **WHEN** the line is `const user: User = create` and candidates include `createUser` and `createCat`
- **THEN** `createUser` ranks first even if `createCat` has a higher fine fuzzy score

#### Scenario: Exact typed name overrides contextual preference
- **WHEN** the current line references `User` but the typed query is `createCat`
- **THEN** exact `createCat` ranks above fuzzy `createUser`

#### Scenario: Identifier naming conventions
- **WHEN** the line references `User` and otherwise equally relevant candidates include `createUser`, `create_user`, and `abuser`
- **THEN** the first two receive User affinity and `abuser` does not

#### Scenario: Query does not boost itself
- **WHEN** the only identifier on the line is the active query `create`
- **THEN** its own text contributes no current-line affinity

#### Scenario: Ignore prose and invalidate changed context
- **WHEN** the only occurrence of `User` is in a comment or string, or a code occurrence is edited to `Cat` without changing the query
- **THEN** prose contributes no affinity and ranking reflects the updated code context

### Requirement: Ranking uses the applicable filter text and base

Completion SHALL assess relevance against server filter text when provided, otherwise label. It SHALL account for completion replacement boundaries rather than assuming the entire receiver is part of the query. If a base cannot be determined reliably, the ambiguous group SHALL receive neutral text relevance without changing native eligibility.

#### Scenario: Filter text differs from the visible label
- **WHEN** an item has filter text `print` and a visible signature label `print(value)` for query `print`
- **THEN** its relevance is assessed as an exact match

#### Scenario: Member completion after a receiver
- **WHEN** completion is requested after `object.pr`
- **THEN** the applicable member base is `pr` rather than `object.pr`

#### Scenario: Unicode before the replacement range
- **WHEN** a server uses UTF-16 edit positions on a line containing multibyte text
- **THEN** ranking and acceptance use the correct replacement boundary without splitting characters

### Requirement: Deprecation breaks text relevance ties

Among equally text-relevant candidates, completion SHALL prefer nondeprecated items before deprecated items. Missing deprecation metadata SHALL be treated as nondeprecated. Deprecated items SHALL remain available.

#### Scenario: Equal relevance with deprecated alternative
- **WHEN** equally relevant candidates differ only in deprecation status
- **THEN** the supported candidate ranks first and the deprecated candidate remains selectable

#### Scenario: Exact deprecated item remains discoverable
- **WHEN** a deprecated candidate exactly matches the query and a supported candidate only fuzzily matches
- **THEN** the exact candidate ranks first

### Requirement: Server ordering has a defined scope

With one enabled completion client, equally text-relevant and equally deprecated candidates SHALL follow server sort text, using label when sort text is absent, before syntax preferences. With multiple enabled completion clients, ranking SHALL omit server sort text across the entire candidate set and use the remaining common rules.

#### Scenario: Single server preference beats syntax preference
- **WHEN** text relevance and deprecation tie, the server orders a variable before a class, and syntax suggests a type
- **THEN** the variable retains its server preference

#### Scenario: Independent server ordering scales
- **WHEN** two enabled completion clients use incompatible sort key formats
- **THEN** their raw sort keys do not determine merged ordering

### Requirement: Syntax hints are conservative tie-breakers

Completion SHALL use confidently identified syntax only after text relevance, deprecation, and applicable server ordering tie. Initial support SHALL cover Lua member/method positions and TypeScript/TSX type, member, and import positions. Syntax hints SHALL never remove candidates or claim semantic type or scope knowledge.

#### Scenario: Type position favors a type candidate on a tie
- **WHEN** equally relevant candidates with equal server preference include a class and variable in a confirmed TypeScript type annotation
- **THEN** the class ranks first

#### Scenario: Lua colon position favors callable kinds on a tie
- **WHEN** all earlier ranking stages tie after `object:` and candidates include a method and a field
- **THEN** the method ranks first without removing the field

#### Scenario: Generic member access does not favor fields over methods
- **WHEN** all earlier stages tie after `object.` and candidates include a field and method
- **THEN** member access alone does not give either kind an advantage over the other

#### Scenario: Function argument remains neutral
- **WHEN** the cursor is inside a call argument and no stronger syntax classification applies
- **THEN** completion does not automatically prefer functions over values

### Requirement: Uncertain syntax fails neutrally

Completion SHALL use neutral syntax preferences for missing or unsupported parsers, unusable local syntax, ambiguous injections, general strings, comments, and unknown contexts. Failure to obtain syntax SHALL not interrupt completion or trigger parser installation.

#### Scenario: Incomplete member expression
- **WHEN** the user types `object.` or `object:` and the local tree cannot confidently classify it
- **THEN** completion still works with neutral syntax preferences

#### Scenario: Unsupported language or missing parser
- **WHEN** the current grammar has no supported context adapter or no available parser
- **THEN** normal relevance and server ranking continue without errors

#### Scenario: Comment and string completion
- **WHEN** a server offers documentation tags in a comment or paths in a general string
- **THEN** syntax classification does not suppress those items

### Requirement: Snippets receive a weak preference penalty

After text relevance, deprecation, applicable server ordering, and syntax fit tie, completion SHALL place ordinary items before snippet-kind items. Unknown ordinary kinds SHALL have no global priority penalty.

#### Scenario: Equally ranked ordinary and snippet items
- **WHEN** an ordinary item and snippet tie through syntax fit
- **THEN** the ordinary item appears first

#### Scenario: Exact snippet beats weak ordinary match
- **WHEN** a snippet exactly matches the query and an ordinary item only fuzzily matches
- **THEN** the snippet ranks first and remains expandable on acceptance

### Requirement: Ordering is deterministic and internally consistent

Ranking SHALL use one fixed policy for a completion snapshot and deterministic final tie-breakers for distinguishable items. It SHALL be irreflexive and transitive, tolerate missing optional metadata, and give empty bases neutral text relevance. Fully equivalent items MAY compare equal.

#### Scenario: Response order changes
- **WHEN** the same distinguishable candidate set and completion state arrive in different orders
- **THEN** the menu order is the same

#### Scenario: Multiple-client comparison triples
- **WHEN** three candidates span two clients and include equal labels or missing optional metadata
- **THEN** comparing them cannot produce a cycle and does not throw

#### Scenario: Query or cursor changes
- **WHEN** the user edits the base, moves the cursor, or changes buffers
- **THEN** subsequent ranking reflects the new state

### Requirement: Completion menus are bounded and readable

The native menu SHALL show at most 10 item rows and occupy at most 70 content columns, shrinking to fit the screen. Display names SHALL be single-line and bounded to 45 display cells; secondary descriptions SHALL be single-line and bounded to 24 display cells, with Unicode-safe truncation. Existing wheat colors, rounded borders, and opaque surfaces SHALL remain.

#### Scenario: Large completion result
- **WHEN** a server returns hundreds of items with long names and descriptions
- **THEN** the menu stays within its bounds and undisplayed items remain navigable

#### Scenario: Narrow screen and wide characters
- **WHEN** a label includes wide characters and the screen has fewer than 70 available columns
- **THEN** the menu fits and truncation preserves complete characters

### Requirement: Presentation preserves native acceptance

Display formatting and sorting SHALL preserve full insertion text, snippet expansion, completion edits, auto-imports, resolve behavior, commands, and native item identity. Items sharing a displayed name but performing different edits SHALL remain distinct. Existing no-selection Enter behavior and explicit acceptance mappings SHALL remain.

#### Scenario: Truncated name with auto-import
- **WHEN** the user accepts an item whose displayed label was shortened and which includes an import edit
- **THEN** native completion inserts the full intended text and applies the import

#### Scenario: Same label with different actions
- **WHEN** two items share a label but import from different modules or apply different edits
- **THEN** both remain available with their respective native acceptance behavior

#### Scenario: Enter without a selection
- **WHEN** the popup is open without a selected candidate and the user presses Enter
- **THEN** completion closes and a newline is inserted

### Requirement: Buffer words are explicitly accessible in LSP buffers

In an enabled ordinary editing buffer, the insert-mode `<C-x><C-n>` sequence SHALL switch to native current-buffer, window-buffer, and loaded-buffer word completion even when LSP is attached. An open completion SHALL be cancelled before switching. `<C-Space>` SHALL retain its current LSP/manual behavior. Automatic fallback after an empty response is outside this version.

#### Scenario: LSP has no useful suggestion
- **WHEN** LSP is attached and the user invokes `<C-x><C-n>`
- **THEN** matching configured buffer words become available without detaching LSP

#### Scenario: User switches an open popup
- **WHEN** an LSP popup is open and the user invokes buffer-word fallback
- **THEN** the LSP selection is cancelled and word completion starts without accepting it

### Requirement: Completion respects existing buffer restrictions

Completion improvements SHALL preserve disabled completion flags, prompt and special-buffer restrictions, floating-window documentation restrictions, terminal command sources and insertion repair, and Russian/English mapping support. New mappings SHALL use the existing layout-aware mapping layer.

#### Scenario: Terminal command input
- **WHEN** completing shell commands or paths in the terminal command buffer
- **THEN** the existing terminal source and acceptance repair continue to work

#### Scenario: Disabled or floating input
- **WHEN** a buffer disables completion or is a floating input with documentation popups suppressed
- **THEN** ranking and fallback integration respect those existing restrictions
