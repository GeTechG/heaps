## Why
`h2d.Text` aligns text left, right or centred, but has no justified layout: a UI built on it (Sprout's `Label` with `horizontalAlignment: fill`, as Godot's `HORIZONTAL_ALIGNMENT_FILL`) cannot stretch wrapped lines to the full width (HPS-30, for SPR-295).

## What Changes
- New `h2d.Align.Justify`. With `maxWidth` set, a line the word wrap broke is stretched to `maxWidth` by spreading the free space over the spaces between its words. The last line of a paragraph, a line that ends on a forced break (`\n`), a line without inner spaces and any text without `maxWidth` are laid out as `Left`.
- Kerning and `letterSpacing` count in the stretched width; `textWidth` and `calcTextWidth` measure the stretched layout.
- `h2d.HtmlText` lays out `Justify` as `Left`.

## Capabilities

### New Capabilities

### Modified Capabilities
- `h2d-text`: adds the justified alignment.

## Impact
`h2d/Text.hx` (the `Align` enum and `initGlyphs`), `h2d/HtmlText.hx` (`nextLine`), plus the test `tests/TextJustifyTest.hx`. Existing alignments do not change.
