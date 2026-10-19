## Why
With `textAlign` set to `Center`, `Right`, `MultilineCenter` or `MultilineRight`, `h2d.Text.initGlyphs` takes the start offset of the first line from `lines[0]`, the widths `splitRawText` measured. That array is empty when no line is ever flushed — for instance when the glyphs of the font have negative widths, so `x` never passes the left margin. On HashLink `lines[0]` then reads 0; on JS it is `undefined`, and `calcWidth`, hence `textWidth`, becomes NaN. A NaN width sends a layout that measures the text (HaxeUI) into an endless loop (HPS-23, found in SPR-224).

## What Changes
- `h2d.Text.initGlyphs`: with no measured line, the aligned start offset is 0 — what HashLink already gives.

## Capabilities

### New Capabilities
- `h2d-text`: the alignment offset of `h2d.Text` is finite even when no line was measured.

### Modified Capabilities

## Impact
`h2d/Text.hx` only, plus the test `tests/TextAlignEmptyTest.hx`. HashLink output does not change; JS gives the same 0 offset instead of NaN.
