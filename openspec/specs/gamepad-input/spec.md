# gamepad-input Specification

## Purpose
`hxd.Pad.wait` tells an application about every gamepad it can use, whenever the gamepad became available.

## Requirements

### Requirement: wait reports the gamepads already connected
The first call of `hxd.Pad.wait( onPad )` SHALL call `onPad` for every gamepad the platform already exposes as connected, and every gamepad connected later SHALL be reported when it connects. A gamepad SHALL be reported once per connection: an index that is already tracked is not reported again until it has disconnected.

#### Scenario: Gamepad activated before wait (JS)
- **WHEN** `navigator.getGamepads()` lists a connected gamepad whose `gamepadconnected` event fired before the first `hxd.Pad.wait( onPad )`
- **THEN** `onPad` is called for it during that `wait` call

#### Scenario: Null and disconnected entries (JS)
- **WHEN** `navigator.getGamepads()` returns `null` entries or entries whose `connected` is false at the first `wait` call
- **THEN** `onPad` is not called for them

#### Scenario: getGamepads fails (JS)
- **WHEN** `navigator.getGamepads()` throws at the first `wait` call
- **THEN** it is treated as an empty list: no gamepad is reported and `wait` raises no error

#### Scenario: Listed and then announced (JS)
- **WHEN** a gamepad was reported by `wait` from `navigator.getGamepads()` and the browser then fires `gamepadconnected` for the same index
- **THEN** `onPad` is not called a second time

#### Scenario: Connected after wait (JS)
- **WHEN** `gamepadconnected` fires for an index that is not tracked
- **THEN** `onPad` is called for it

### Requirement: Pad holds the callback of the latest wait
`hxd.Pad` SHALL hold a single callback, the one passed to the latest `wait` call: every report SHALL go to it, and a later `wait` call SHALL replace it without reporting the tracked gamepads again. An exception thrown by the callback SHALL propagate to whoever triggered the report.

#### Scenario: Second wait
- **WHEN** a gamepad was reported to `a` by `wait( a )`, then `wait( b )` is called and another gamepad connects
- **THEN** `b` is not called for the first gamepad, the second one is reported to `b`, and `a` is not called again

#### Scenario: Callback throws
- **WHEN** the callback throws while a gamepad connected before `wait` is reported
- **THEN** the exception propagates out of that `wait` call
