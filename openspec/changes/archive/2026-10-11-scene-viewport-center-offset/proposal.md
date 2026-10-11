## Why
With a centered `LetterBox` or `Fixed` scale mode `h2d.Scene.checkResize` rounds the margin twice, differently: the viewport the scene is drawn with is snapped to a whole scene pixel (a multiple of `zoom` window pixels, which is what keeps tiles gap-free), while `offsetX` / `offsetY`, used to convert window coordinates to scene coordinates, are snapped to a window pixel. `Fixed(…, 180, 6)` in a window 1091 px high has an 11 px margin: the picture is drawn from Y=0 and `offsetY` is 5. `Camera.screenToCamera`, `Scene.mouseX/Y` and the events of `h2d.Interactive` are then off the picture by up to `zoom - 1` window pixels.

## What Changes
- `h2d.Scene.checkResize`, `Center` alignment: `offsetX` / `offsetY` are the window-pixel position the viewport is actually drawn at (the margin snapped to a whole scene pixel), not an independently rounded half margin.
- The drawn viewport does not move. The render zone of `Camera.clipViewport` is derived from the drawn viewport and already agrees with it.

## Capabilities

### New Capabilities
- `scene-viewport`: where `h2d.Scene` places its viewport in the window for an aligned scale mode, and that drawing and input use the same placement.

### Modified Capabilities

## Impact
`h2d/Scene.hx` (`checkResize`), a new test `tests/SceneViewportTest.hx`. `Left` / `Top` / `Right` / `Bottom` alignments and the other scale modes are untouched. With `Center`, `offsetX` / `offsetY` change by less than `zoom` window pixels, i.e. less than one scene pixel.
