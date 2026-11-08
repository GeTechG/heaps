## Why

On JS, `hxd.Window` listens to `touchstart`, `touchmove` and `touchend`, but not to `touchcancel`. A touch the browser cancels (a system gesture, a menu opening, a lost touch) never gets a release: the game sees it held until some later release or focus loss.

## What Changes

- On JS, a touch the browser cancels is released like one that ends: an `ERelease` with its `touchId` at its last position. `hxd.Event` has no way to mark a release as cancelled, so the release is the ordinary one.
- The `touchcancel` listener is added and removed together with the other touch listeners, so `dispose` still leaves nothing on the page.

## Capabilities

### New Capabilities
- `touch-input`: how `hxd.Window` turns the browser's touches into events on JS, starting with what a cancelled touch sends.

### Modified Capabilities

## Impact

`hxd/Window.js.hx` only. No API change.
