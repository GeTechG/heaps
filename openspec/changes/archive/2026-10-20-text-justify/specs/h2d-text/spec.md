## ADDED Requirements

### Requirement: justified alignment
`h2d.Text` with `textAlign = Justify` and a `maxWidth` SHALL stretch every line the word wrap broke so that the advance of its last visible glyph ends at `maxWidth` (the line width `Right` and `textWidth` measure: by glyph advance, not by the drawn tile), by adding the same extra advance to each space between its first and last visible glyph. Kerning and `letterSpacing` SHALL be counted in that width. The last line of a paragraph, a line followed by a forced break (`\n`), a line with no space between visible glyphs, a line already at least `maxWidth` wide, and every line of a text without `maxWidth` SHALL be laid out as with `Left`. `textWidth` and `calcTextWidth` SHALL measure a stretched line as `maxWidth` wide, trailing spaces excluded. `h2d.HtmlText` SHALL lay out `Justify` as `Left`.

#### Scenario: Two wrapped lines
- **WHEN** a text wraps into two lines with `textAlign = Justify`
- **THEN** the advance of the first line ends at `maxWidth` (± 1 px) and the second line has the glyph positions it has with `Left`

#### Scenario: A line without spaces
- **WHEN** a wrapped line has no space between its visible glyphs
- **THEN** it is laid out as with `Left`

#### Scenario: Forced break
- **WHEN** a line ends on `\n`
- **THEN** it is laid out as with `Left`
