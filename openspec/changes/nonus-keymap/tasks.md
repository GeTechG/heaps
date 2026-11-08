## 1. Map unknown characters by position

- [x] 1.1 `tests/NonUsKeymapTest.hx`: HashLink/SDL test feeding synthetic `sdl.Event` key events to `hxd.Window` — the scenarios of `keyboard-input` (all 26 Russian letters on KeyDown and KeyUp, `ё` on grave, Latin letters, numpad Enter, `ù`); fails before 1.2
- [x] 1.2 `hxd/Window.hl.hx`: one mapping for `KeyDown`/`KeyUp` that takes ASCII, mapped keysyms and scancode keycodes from `CODEMAP` and any other character from the scancode position table — checked by 1.1 passing
- [x] 1.3 `tests/TextInputTest.hx` on HashLink still passes; `haxe all.hxml`; AGENTS.md *Checks*

## Workflow follow-up

- Sprout bumps its heaps gitlink and closes SPR-565.
