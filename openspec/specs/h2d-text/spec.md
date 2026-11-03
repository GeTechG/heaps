# h2d-text Specification

## Purpose
How `h2d.Text` lays out its glyphs: word wrap, alignment (justified included) and the measured size.

## Requirements

### Requirement: the alignment offset is defined when no line was measured
When `h2d.Text` lays out text with `textAlign` `Center`, `Right`, `MultilineCenter` or `MultilineRight` and the word wrap measured no line, the start offset of the text SHALL be 0 on every target, and `textWidth` SHALL be a finite number. It SHALL NOT read the offset of a line that does not exist.

#### Scenario: Negative glyph widths on JS
- **WHEN** a font whose glyphs have negative widths renders `"Resume"` with `textAlign = Center` on JS
- **THEN** `textWidth` is a finite number, as on HashLink

#### Scenario: Measured lines
- **WHEN** the word wrap measured at least one line
- **THEN** the start offset is that of the first line, as before

### Requirement: justified alignment
`h2d.Text` with `textAlign = Justify` and a `maxWidth` SHALL stretch every line the word wrap broke so that the advance of its last visible glyph ends at `maxWidth`, by adding the same extra advance to each space between its first and last visible glyph. The line width SHALL be the one `Right` and `textWidth` measure: by glyph advance, not by the drawn tile, with kerning and `letterSpacing` counted.

#### Scenario: Two wrapped lines
- **WHEN** a text wraps into two lines with `textAlign = Justify`
- **THEN** the advance of the first line ends at `maxWidth` (± 1 px) and the second line has the glyph positions it has with `Left`

#### Scenario: Letter spacing
- **WHEN** a justified text with a non-zero `letterSpacing` wraps
- **THEN** the advance of each stretched line, `letterSpacing` and kerning included, ends at `maxWidth` (± 1 px)

### Requirement: lines that justified alignment leaves as Left
With `textAlign = Justify`, the last line of a paragraph, a line followed by a forced break (`\n`), a line with no space between visible glyphs, a line already at least `maxWidth` wide, and every line of a text without `maxWidth` SHALL be laid out as with `Left`.

#### Scenario: A line without spaces
- **WHEN** a wrapped line has no space between its visible glyphs
- **THEN** it is laid out as with `Left`

#### Scenario: Forced break
- **WHEN** a line ends on `\n`
- **THEN** it is laid out as with `Left`

#### Scenario: No maxWidth
- **WHEN** a text with `textAlign = Justify` has no `maxWidth`
- **THEN** every line is laid out as with `Left`

### Requirement: a justified line measures maxWidth
`h2d.Text.textWidth` and `calcTextWidth` SHALL measure a line stretched by justified alignment as `maxWidth` wide, trailing spaces excluded.

#### Scenario: Width of a justified paragraph
- **WHEN** a justified text wraps into a stretched line and a shorter last line
- **THEN** `textWidth` is `maxWidth`

### Requirement: HtmlText lays out Justify as Left
`h2d.HtmlText` SHALL lay out `textAlign = Justify` as `Left`.

#### Scenario: Justified HtmlText
- **WHEN** an `h2d.HtmlText` with a `maxWidth` and `textAlign = Justify` wraps
- **THEN** its glyphs have the positions they have with `Left`
