## ADDED Requirements

### Requirement: a character key of a non-Latin layout is the key of its position
On HashLink/SDL, when a key event's keycode is a character above ASCII that has no key of its own, `hxd.Window` SHALL report the `hxd.Key` of the key's physical position (letters, digits and the US punctuation keys) for both `EKeyDown` and `EKeyUp`. Such a character SHALL never be reported as a key SDL identifies by scancode only (arrows, Home/End, numpad, function keys).

#### Scenario: Russian letter on the H key
- **WHEN** SDL sends `KeyDown` with keycode U+0440 (`р`) and the scancode of H
- **THEN** the event targets receive `EKeyDown` with `keyCode` `hxd.Key.H`, not `NUMPAD_ENTER`

#### Scenario: Every letter of a Russian layout
- **WHEN** SDL sends, for each key `A`…`Z`, `KeyDown` and `KeyUp` with the Russian letter of that key and its scancode
- **THEN** both events carry the `hxd.Key` of that Latin letter

#### Scenario: Character on a digit or punctuation key
- **WHEN** SDL sends `KeyDown` with keycode U+0451 (`ё`) and the scancode of the grave key
- **THEN** the event carries `hxd.Key.QWERTY_TILDE`

### Requirement: Latin and scancode keys keep their key
On HashLink/SDL, `hxd.Window` SHALL keep reporting an ASCII keycode, a non-ASCII keycode with a key of its own, and a keycode SDL derives from a scancode as the same `hxd.Key` as before position mapping existed.

#### Scenario: Latin letter
- **WHEN** SDL sends `KeyDown` with keycode `a` and the scancode of A
- **THEN** the event carries `hxd.Key.A`

#### Scenario: Numpad Enter
- **WHEN** SDL sends `KeyDown` with keycode `SDLK_KP_ENTER` (scancode bit and 88)
- **THEN** the event carries `hxd.Key.NUMPAD_ENTER`

#### Scenario: Mapped AZERTY character
- **WHEN** SDL sends `KeyDown` with keycode `ù` (249)
- **THEN** the event carries `hxd.Key.QWERTY_TILDE`, as before
