## 1. Implementation

- [ ] 1.1 `hxd/Pad.hx`, JS: one function registers a `js.html.Gamepad` (used by the `gamepadconnected` handler), skipping an index already tracked
- [ ] 1.2 `hxd.Pad.wait`, JS: the first call registers every connected entry of `navigator.getGamepads()`

## 2. Verification

- [ ] 2.1 `tests/PadWaitTest.hx` (node, stubbed `window`/`navigator`): a gamepad visible before `wait` is reported once; its later `gamepadconnected` event does not report it again; a new gamepad's event does
- [ ] 2.2 `haxe all.hxml` builds
