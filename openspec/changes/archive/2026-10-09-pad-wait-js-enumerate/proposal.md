## Why
On JS `hxd.Pad.wait` only listens for `gamepadconnected`. A gamepad whose event fired before `wait` was called (a button pressed while the page was loading) is never reported until it is reconnected. On HashLink/SDL `wait` enumerates the devices already connected; the web target does not.

## What Changes
- `hxd.Pad.wait` on JS: the first call also walks `navigator.getGamepads()` and reports every connected gamepad, through the same path as the `gamepadconnected` handler.
- A gamepad index that is already tracked is not reported a second time, so a browser that both lists a gamepad and fires its event yields one `onPad` call.

## Capabilities

### New Capabilities
- `gamepad-input`: which gamepads `hxd.Pad.wait` reports, and when.

### Modified Capabilities

## Impact
`hxd/Pad.hx` (the `#if js` branch only), a new test `tests/PadWaitTest.hx`. Other targets are untouched. `onPad` can now be called synchronously from inside `wait` on JS, as it already can on HashLink/SDL.
