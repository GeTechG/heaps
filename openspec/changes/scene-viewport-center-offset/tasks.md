## 1. Implementation

- [x] 1.1 `h2d.Scene.checkResize`, `Center` alignment: compute `offsetX` / `offsetY` from the same snapped margin as `viewportX` / `viewportY`

## 2. Verification

- [x] 2.1 `tests/SceneViewportTest.hx`: for `Fixed` and `LetterBox` over a range of window sizes, zooms and alignments, `offsetX/Y` equals the window-pixel position given by `viewportX/Y`
- [x] 2.2 `haxe all.hxml` builds
