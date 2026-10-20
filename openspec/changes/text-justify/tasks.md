## 1. Implementation

- [ ] 1.1 `h2d.Align.Justify` with its documentation
- [ ] 1.2 `h2d.Text.initGlyphs`: stretch the inner spaces of a wrapped line to `maxWidth`, measure it as `maxWidth`
- [ ] 1.3 `h2d.HtmlText.nextLine`: `Justify` as `Left`

## 2. Verification

- [ ] 2.1 `tests/TextJustifyTest.hx`: two wrapped lines — the first ends at `maxWidth`, the last is as `Left`; a line without spaces and a forced break are not stretched; kerning and `letterSpacing` included
- [ ] 2.2 `haxe all.hxml` builds; `tests/TextAlignEmptyTest.hx` and `tests/TextWordBreakTest.hx` still pass
