# window-dispose Specification

## Purpose
What `hxd.Window.dispose()` leaves on the page on JS.

## Requirements

### Requirement: a disposed window leaves no listener on the page
On JS, after `hxd.Window.dispose()` no listener added by that window SHALL remain on its canvas, on `window` or on `document`, whichever of the default canvas, a custom canvas or `globalEvents` it was created with. This covers the listeners of the constructor and those of `addDragAndDropTarget`. An event reaching the canvas, `window` or `document` after that SHALL send nothing to the window's event targets. The text input element is removed from the page, as `text-input` states, and its listeners go with it.

#### Scenario: Global events
- **GIVEN** a window created with `globalEvents`
- **WHEN** it is disposed and an input event then reaches `window` or the canvas
- **THEN** the window's event targets receive nothing, and nothing of it remains registered on `window`

#### Scenario: Same canvas, new window
- **GIVEN** a window on a canvas, disposed, and a new window created on that canvas
- **WHEN** an input event reaches the canvas
- **THEN** only the new window's event targets receive it

#### Scenario: Drag and drop target
- **GIVEN** a window with a target added by `addDragAndDropTarget`
- **WHEN** the window is disposed and a `drop` then reaches the canvas
- **THEN** the target is not called and the browser's default for the event is not prevented

#### Scenario: No browser
- **GIVEN** `js.Browser.supported` is false, so the constructor touched nothing on the page
- **WHEN** the window is disposed
- **THEN** `dispose` returns without an error
