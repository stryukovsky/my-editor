# Markdown Math Rendering

## ADDED Requirements

### Requirement: Unicode symbols in Markdown math

The configuration SHALL display supported LaTeX symbol commands as Unicode in recognized inline and display math for `markdown` and `todotxt-preview` buffers while rendering is enabled. Support SHALL cover Greek letters and variants, common operators, arrows, and the specified dots. Complete command names SHALL be matched without replacing a prefix of an unknown command.

#### Scenario: Greek letters and operators

- **WHEN** a Markdown buffer contains `$\alpha + \beta \leq \Gamma \times \infty$`
- **THEN** the corresponding commands display as `α + β ≤ Γ × ∞`
- **AND** math delimiters retain their existing source presentation

#### Scenario: Initial symbol coverage

- **WHEN** math contains standard lowercase Greek commands, uppercase Greek commands with distinct glyphs, or common Greek variants
- **THEN** their Unicode counterparts display
- **AND** `\times`, `\pm`, `\leq`, `\geq`, `\neq`, `\infty`, and `\rightarrow` display as `×`, `±`, `≤`, `≥`, `≠`, `∞`, and `→` respectively

#### Scenario: Display math and custom preview filetype

- **WHEN** a `markdown` or `todotxt-preview` buffer contains a multiline `$$` math region with `\theta \rightarrow \Omega`
- **THEN** the commands display as `θ → Ω` within that region

### Requirement: Distinct Unicode dot symbols

The renderer SHALL preserve the meanings of dot commands through these mappings: `\cdot` → `⋅` (U+22C5), `\bullet` → `•` (U+2022), `\ldots` and `\dots` → `…` (U+2026), `\cdots` → `⋯` (U+22EF), `\vdots` → `⋮` (U+22EE), and `\ddots` → `⋱` (U+22F1).

#### Scenario: Multiplication and ellipsis dots

- **WHEN** math contains `a \cdot b \quad \ldots \cdots \vdots \ddots \bullet \dots`
- **THEN** its dot commands display respectively as `⋅`, `…`, `⋯`, `⋮`, `⋱`, `•`, and `…`
- **AND** the unsupported structural command `\quad` remains unchanged

### Requirement: Display-only transformation and rendering lifecycle

Rendering SHALL preserve buffer and saved-file bytes, the modified flag, and undo history. Existing render-markdown toggles SHALL enable and remove symbol rendering and restore the applicable window options. Disabling rendering SHALL reveal the original commands without stale marks. Supported symbols SHALL render without external formula converters.

#### Scenario: Source is preserved

- **WHEN** a file containing `$\alpha \cdot x$` is opened, rendered, and saved without edits
- **THEN** the saved text still contains `$\alpha \cdot x$`
- **AND** rendering itself does not mark the buffer modified or create undo entries

#### Scenario: Toggle and edit

- **WHEN** rendering is toggled off and on, then `\alpha` is edited to `\beta`
- **THEN** toggle-off reveals the original source and toggle-on shows supported symbols
- **AND** the edited symbol refreshes to β without leaving stale α marks

#### Scenario: Converter executables are absent

- **WHEN** neither `utftex` nor `latex2text` is installed
- **THEN** supported symbols still render without converter warnings or error placeholders

### Requirement: Rendering scope and surrounding presentation

Symbol substitution SHALL be restricted to recognized Markdown math regions. Ordinary prose, inline code, fenced code, unrelated filetypes, unknown commands, escaped command text, and unsupported LaTeX structure SHALL remain unchanged. The existing visibility of Markdown source markers, including backticks, SHALL be preserved in rendered buffers. Query changes SHALL NOT affect unrelated buffers and SHALL be cleaned up with rendering lifecycle changes.

#### Scenario: Code and prose remain literal

- **WHEN** `\alpha` appears in ordinary prose, an inline code span, or a fenced code block
- **THEN** the command remains literal
- **AND** code backticks remain visible as in the current configuration

#### Scenario: Unknown and escaped commands

- **WHEN** math includes `\alphabogus`, `\unknownsymbol`, or an escaped backslash followed by `alpha`
- **THEN** those sequences remain unchanged
- **AND** the renderer does not convert the `\alpha` prefix inside `\alphabogus`

#### Scenario: Other buffers and incomplete edits

- **WHEN** a rendered Markdown buffer shares a session with a non-Markdown buffer, or a math delimiter is temporarily removed while editing
- **THEN** unrelated buffer presentation remains unchanged
- **AND** incomplete math is left readable without errors and valid math renders again after repair
