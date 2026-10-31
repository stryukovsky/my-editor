# Markdown Math Rendering

## ADDED Requirements

### Requirement: Unicode symbols in Markdown math

The configuration SHALL display supported LaTeX symbol commands as Unicode in recognized inline and display math for `markdown` and `todotxt-preview` buffers while rendering is enabled. Support SHALL cover Greek letters and variants, common operators, arrows, and the specified dots. Complete command names SHALL be matched without replacing a prefix of an unknown command.

#### Scenario: Greek letters and operators

- **WHEN** a Markdown buffer contains `$\alpha + \beta \leq \Gamma \times \infty$`
- **THEN** the corresponding commands display as `α + β ≤ Γ × ∞`
- **AND** inline math delimiters display as spaces and opening display delimiters as a LaTeX icon, while source bytes remain unchanged

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


### Requirement: Delimiter sizing commands

Within recognized math regions the renderer SHALL hide `\left` and `\right` while retaining their visible delimiters. Escaped braces and vertical bars SHALL display as their corresponding symbols. A dot used as an invisible delimiter SHALL be hidden. Superscripts, subscripts and accents SHALL retain their original syntax.

#### Scenario: Sized delimiters

- **WHEN** math contains `\left( x \right)` or `\left\langle x \right\rangle`
- **THEN** it displays as `( x )` or `⟨ x ⟩` respectively

#### Scenario: Invisible and escaped delimiters

- **WHEN** math contains `\left. x \right|`, `\left\{x\right\}`, or `\left\|x\right\|`
- **THEN** it displays as ` x |`, `{x}`, or `‖x‖` respectively

#### Scenario: Structural expressions remain literal

- **WHEN** math contains `x^2 a_i \hat{x}`
- **THEN** those expressions retain their original syntax

### Requirement: Additional common symbols

The supported command set SHALL include common arrows, comparisons, arithmetic, sets, logic, calculus symbols, delimiters and named functions without invoking an external converter.

#### Scenario: Arrows, sets and logic

- **WHEN** math contains `\leftarrow \leftrightarrow \Rightarrow \Leftrightarrow \mapsto \in \subseteq \cup \forall \exists`
- **THEN** these commands display as `← ↔ ⇒ ⇔ ↦ ∈ ⊆ ∪ ∀ ∃`

#### Scenario: Calculus and named functions

- **WHEN** math contains `\partial \nabla \int \sum \prod \sin x \cos x \log x`
- **THEN** these commands display as `∂ ∇ ∫ ∑ ∏ sin x cos x log x`


### Requirement: Linear fractions and square roots

Complete braced `\frac`, `\dfrac` and `\tfrac` commands SHALL display as parenthesized numerator and denominator separated by U+00F7 (`÷`). Complete braced `\sqrt` commands SHALL display as `√` followed by a parenthesized argument. Nested supported expressions SHALL render recursively while retaining scripts and accents as written. Incomplete, unbraced and indexed forms SHALL remain readable as source.

#### Scenario: Fraction grouping and division sign

- **WHEN** math contains `\frac{xy}{x+a}`
- **THEN** it displays as `(xy) ÷ (x+a)`

#### Scenario: Nested expressions from the AMM note

- **WHEN** math contains `\sqrt{\frac{k}{c}}` or `\frac{\sqrt{k}}{2c^{3/2}}`
- **THEN** it displays as `√((k) ÷ (c))` or `(√(k)) ÷ (2c^{3/2})` respectively

#### Scenario: Unsupported or incomplete argument form

- **WHEN** math contains `\sqrt[3]{x}`, `\frac12`, or an incomplete braced command
- **THEN** that structure remains literal without errors

### Requirement: Terminal math spacing

The renderer SHALL display `\quad` as two spaces and `\qquad` as four spaces. Escaped spaces and small positive spacing commands SHALL display as one space, while `\!` SHALL be hidden.

#### Scenario: Mixing constraint spacing

- **WHEN** math contains `M=\theta A+(1-\theta)B,\qquad 0\le\theta\le1`
- **THEN** `\qquad` displays as four spaces and the other supported commands display as symbols

### Requirement: Consistent math text color

While rendering is enabled, both formula source and replacement text SHALL use the current Normal foreground. The color SHALL refresh on theme changes. Global Conceal colors and unrelated buffer highlighting SHALL remain unchanged.

#### Scenario: Theme uses blue math and gray conceal

- **WHEN** the theme colors math blue and concealed text gray
- **THEN** rendered formulas and Unicode replacements share the Normal foreground

#### Scenario: Theme foreground changes

- **WHEN** a ColorScheme event changes the Normal foreground
- **THEN** formula source and replacements use the updated foreground together


### Requirement: Dollar delimiters display as spaces

While math rendering is enabled, inline dollar delimiters SHALL display as spaces. The opening `$$` of display math SHALL display as the LaTeX Nerd Font icon `` followed by one space; the closing `$$` SHALL display as two spaces. Disabling rendering SHALL reveal the original delimiters. Escaped literal dollar signs and dollar signs in code or prose SHALL remain unchanged.

#### Scenario: Inline delimiters

- **WHEN** math contains `$\alpha$` with rendering enabled
- **THEN** it displays as a space, `α`, and a space
- **AND** the source still contains `$\alpha$`

#### Scenario: Display delimiters

- **WHEN** a display math block is delimited by `$$`
- **THEN** the opening `$$` displays as `` followed by a space and the closing `$$` as two spaces, without removing either source line

#### Scenario: Literal dollars and toggle

- **WHEN** dollars occur in inline code, fenced code, or as an escaped literal dollar in math
- **THEN** they remain literal
- **AND** disabling rendering restores all original math delimiter dollars
