## ADDED Requirements

### Requirement: wait reports the gamepads already connected
The first call of `hxd.Pad.wait( onPad )` SHALL call `onPad` for every gamepad the platform already exposes as connected, and every gamepad connected later SHALL be reported when it connects. On JS the gamepads already exposed are the non-null, connected entries of `navigator.getGamepads()`; a failure of that call SHALL be treated as an empty list. A gamepad SHALL be reported once per connection: an index that is already tracked is not reported again until it has disconnected.

#### Scenario: Gamepad activated before wait (JS)
- **WHEN** `navigator.getGamepads()` lists a connected gamepad whose `gamepadconnected` event fired before the first `hxd.Pad.wait( onPad )`
- **THEN** `onPad` is called for it during that `wait` call

#### Scenario: Listed and then announced (JS)
- **WHEN** a gamepad was reported by `wait` from `navigator.getGamepads()` and the browser then fires `gamepadconnected` for the same index
- **THEN** `onPad` is not called a second time

#### Scenario: Connected after wait (JS)
- **WHEN** `gamepadconnected` fires for an index that is not tracked
- **THEN** `onPad` is called for it
