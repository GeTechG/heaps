# touch-input Specification

## Purpose
How `hxd.Window` turns the browser's touch events into Heaps events on JS.

## Requirements

### Requirement: a cancelled touch is released
On JS, when the browser cancels touches on the window's element, `hxd.Window` SHALL send, for each cancelled touch, one `ERelease` event carrying that touch's `touchId` and its position in canvas pixels, the same event an ended touch sends. The window SHALL prevent the browser's default for the cancel event, as it does for the other touch events.

#### Scenario: Touch cancelled by the browser
- **GIVEN** a window that received `EPush` for a touch
- **WHEN** the browser cancels that touch
- **THEN** the window's event targets receive one `ERelease` with the same `touchId`

#### Scenario: Several touches cancelled at once
- **GIVEN** two touches pushed on the window
- **WHEN** the browser cancels both in one event
- **THEN** the event targets receive one `ERelease` per touch, each with its own `touchId`

#### Scenario: Disposed window
- **GIVEN** a disposed window
- **WHEN** a touch cancel reaches its element
- **THEN** its event targets receive nothing, as `window-dispose` states
