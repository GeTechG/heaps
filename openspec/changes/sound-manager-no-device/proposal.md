## Why
`hxd.snd.Manager` can play with no driver at all (every channel virtual), but it falls back to that only when the driver constructor throws a `String`. A driver that throws anything else — a HashLink null access when OpenAL opens no device, a `haxe.Exception` — takes the whole program down on the first `Manager.get()` (HPS-29).

## What Changes
- The Manager catches any exception thrown while the driver is created and its sources allocated, disposes a driver that was created, and goes on without a driver.
- `Manager.driverError`: the exception that left the Manager without a driver, `null` while it has one, so the application can show it.
- The other places a driver touches the device were checked: the OpenAL device-change reopen runs in `driver.update()`, which the Manager does not call without a driver; `suspended` only makes channels virtual. Nothing changes there.

## Capabilities

### New Capabilities
- `sound-manager`: what the sound manager does when no audio device can be opened.

### Modified Capabilities

## Impact
`hxd/snd/Manager.hx`, the test `tests/NoDeviceTest.hx` with its stub driver in `tests/nodevice/`. A program that has a device sees no difference.
