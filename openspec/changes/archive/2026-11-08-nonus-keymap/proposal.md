## Why

On HashLink/SDL `hxd.Window` turns an SDL keycode into an `hxd.Key` through one table, in which keycodes derived from a scancode (SDL's bit 30) are folded to `1000 + scancode`. A character keysym of a non-Latin layout is its Unicode code point, and the Cyrillic letters (U+0430…U+044F, 1072…1103) land on the same numbers as the folded arrows, Home/End, the numpad and NumLock: under a Russian layout `р` (U+0440 = 1088) on the H key is `NUMPAD_ENTER`, a phantom submit (HPS-48, found in Sprout SPR-565). SDL 3 hides it today only because its default `SDL_HINT_KEYCODE_OPTIONS` reports the Latin letter of the key; any other hint, binding or SDL version brings it back.

## What Changes

- On HashLink/SDL, a key whose keycode is a character the table does not know (any code point above ASCII without a mapping of its own) is the `hxd.Key` of its physical position: letters `A`…`Z`, digits and the US punctuation keys, read from the event's scancode.
- Such a keycode never reaches the folded-scancode range, so a character can no longer become an arrow or a numpad key.
- ASCII keysyms, the keysyms already mapped (AZERTY `ù`, `§`, …) and scancode-derived keycodes keep their current key.
- A character on a key without a known position keeps its own code point as before.

## Capabilities

### New Capabilities
- `keyboard-input`: how `hxd.Window` turns the platform's key events into `hxd.Key` codes, starting with keys of a non-Latin layout on HashLink/SDL.

### Modified Capabilities

## Impact

`hxd/Window.hl.hx` (the SDL `KeyDown`/`KeyUp` branch) and a new test `tests/NonUsKeymapTest.hx`. No API change.
