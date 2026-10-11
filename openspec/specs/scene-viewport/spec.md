# scene-viewport Specification

## Purpose
`h2d.Scene` places its viewport in the window once: what is drawn and where the pointer is read agree.

## Requirements

### Requirement: drawing and input share one viewport placement
For the scale modes that align the viewport in the window (`LetterBox` and `Fixed`), `h2d.Scene.checkResize` SHALL place the viewport once per axis, and `offsetX` / `offsetY` (window pixels, used to convert window coordinates to scene coordinates and back) SHALL equal the window-pixel position of the scene origin given by `viewportX` / `viewportY` (the transform the scene is drawn with, which the render zone of `Camera.clipViewport` also follows): `offsetX = (viewportX + 1) * engine.width / 2`, and the same for Y. With `Center` alignment the margin before the viewport SHALL be half the free space rounded down to a whole scene pixel, i.e. `floor((engine.width - width * zoom) / (2 * zoom)) * zoom` window pixels, so that scene pixels stay on the window pixel grid for an integer zoom.

#### Scenario: Centered with a margin that is not a whole scene pixel
- **WHEN** the scale mode is `Fixed(320, 180, 6)` with `Center` alignment and the window is 1920 x 1091
- **THEN** the scene is drawn from window Y = 0 and `offsetY` is 0

#### Scenario: Centered with a larger margin
- **WHEN** the scale mode is `Fixed(320, 180, 6)` with `Center` alignment and the window is 1920 x 1107
- **THEN** the scene is drawn from window Y = 12 and `offsetY` is 12

#### Scenario: Pointer over the first drawn scene pixel
- **WHEN** the viewport is centered and the pointer is on the window pixel where the scene origin is drawn
- **THEN** `Camera.screenToCamera` maps it to scene coordinate 0 on that axis
