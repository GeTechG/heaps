# h2d-text Specification

## Purpose
How `h2d.Text` lays out its glyphs: word wrap, alignment and the measured size.

## Requirements

### Requirement: the alignment offset is defined when no line was measured
When `h2d.Text` lays out text with `textAlign` `Center`, `Right`, `MultilineCenter` or `MultilineRight` and the word wrap measured no line, the start offset of the text SHALL be 0 on every target, and `textWidth` SHALL be a finite number. It SHALL NOT read the offset of a line that does not exist.

#### Scenario: Negative glyph widths on JS
- **WHEN** a font whose glyphs have negative widths renders `"Resume"` with `textAlign = Center` on JS
- **THEN** `textWidth` is a finite number, as on HashLink

#### Scenario: Measured lines
- **WHEN** the word wrap measured at least one line
- **THEN** the start offset is that of the first line, as before
