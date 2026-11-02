## Why
On JS, `hxd.Window.dispose()` removes only part of what the constructor put on the page (HPS-44, found during HPS-43). Under `globalEvents` the listeners left on `window` keep the disposed window from being collected and keep it receiving events; when the same canvas is given to a new window, the old one receives its events as well and its handlers can stop their propagation. No spec states what `dispose` must leave behind.

## What Changes
- `dispose()` removes every listener the window added: those on the event element (`element`, the canvas or `window`), on the canvas, on `window` and on `document`, in all three setups (default canvas, custom canvas, `globalEvents`).
- The listeners that were anonymous closures or `onElementFocus.bind(...)` (`blur`, `focus`, `contextmenu`, the first `mousedown` under `globalEvents`) become methods, so that `dispose` can name them. What they do does not change.
- `dispose()` also removes the `dragover` and `drop` listeners of `addDragAndDropTarget` and forgets its targets: not added by the constructor, but the same leak on the same canvas.
- `dispose()` does nothing to the page when `js.Browser.supported` is false: the constructor added nothing there and there is no `element` to remove from.

The constructor's `addEventListener` lines stay as upstream has them and `dispose` gets explicit `removeEventListener` lines, as upstream's own, rather than a registry of listeners: `be92c874` is upstream's start on the same fix and a registry would rewrite both sides of every future merge.

## Capabilities

### New Capabilities
- `window-dispose`: what `hxd.Window.dispose()` leaves on the page on JS.

### Modified Capabilities

## Impact
`hxd/Window.js.hx`. A permanent test under `tests/` is outside this task's footprint: verification runs from a throwaway harness on a DOM stub, and the permanent test is a separate issue.
