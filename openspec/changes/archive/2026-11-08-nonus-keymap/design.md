# Design

## Context

`hxd.Window` on HashLink/SDL maps `sdl.Event.keyCode` through `CODEMAP`, a 2048-entry table that is the identity except where `initChars` sets a key. A keycode with SDL's scancode bit (`1 << 30`) is first folded to `1000 + scancode`. Every SDL key event also carries `scanCode`, the USB HID position of the key, which no layout changes.

## Goals / Non-Goals

**Goals:**
- A character key of any layout is never mistaken for a folded scancode key.
- A letter key under a non-Latin layout gives the `hxd.Key` of its letter, as SDL 3's `latin_letters` does.

**Non-Goals:**
- Changing the keys of Latin layouts or of keycodes SDL derives from scancodes.
- Mapping by position keys outside the US main block (non-US `#`/`\`, international keys).

## Decisions

- **Which keycodes go by position.** A keycode without the scancode bit is taken from the table when it is ASCII (below 128) or when the table maps it to something else than itself; any other keycode is a character the table does not know. Taking only the colliding range (1000 and above) would fix the bug but leave Greek or `ö` as unusable codes; the rule above treats every unknown character the same way. Alternative rejected: moving the folded scancodes out of the way (e.g. to `1 << 16 + scancode`) — it fixes the collision but a Cyrillic letter would still be an unusable code.
- **Position table.** SDL scancodes 4…29 → `A`…`Z`, 30…38 → `NUMBER_1`…`NUMBER_9`, 39 → `NUMBER_0`, 45…49 and 51…56 → the `QWERTY_*` punctuation keys of the same place. A scancode outside it keeps the old result: the code point itself, read through the table only below 1000 so it cannot reach the folded range.
- **One function for both events.** `KeyDown` and `KeyUp` call the same mapping, so a key is released under the code it was pressed with. The event's `keyCode` is no longer rewritten in place except for the left/right modifier echo, which already does it.

## Risks / Trade-offs

- [A game that compared `e.keyCode` to a raw code point above ASCII (e.g. 246 for `ö`)] → such codes were never `hxd.Key` constants; it now gets the key of the position, the same one a US keyboard reports there.
