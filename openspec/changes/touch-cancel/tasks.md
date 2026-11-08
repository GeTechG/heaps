## 1. Release cancelled touches

- [x] 1.1 `hxd/Window.js.hx`: listen to `touchcancel` with `onTouchEnd` next to the other touch listeners, and remove it in `dispose` — checked by 1.2
- [x] 1.2 A throwaway harness on the DOM stub of `tests/WindowDisposeTest.hx` under node: a cancelled touch sends one `ERelease` per touch with its `touchId`, the default is prevented, nothing arrives after `dispose`; fails before 1.1, passes after
- [x] 1.3 `node test.js` of `tests/WindowDisposeTest.hx` still passes; `haxe all.hxml`; AGENTS.md *Checks*

## Workflow follow-up

- Sprout bumps its heaps gitlink and closes TD-36.
