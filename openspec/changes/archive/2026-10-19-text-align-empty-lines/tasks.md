## 1. Implementation

- [x] 1.1 `h2d.Text.initGlyphs`: use 0 as the aligned start offset when `lines` is empty

## 2. Verification

- [x] 2.1 `tests/TextAlignEmptyTest.hx`: a font with negative glyph widths, every centred or right alignment, `textWidth` is finite on JS (fails before 1.1)
- [x] 2.2 `haxe all.hxml` builds; `tests/TextWordBreakTest.hx` still passes
