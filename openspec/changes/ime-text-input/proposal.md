## Why
On HashLink/SDL `hxd.Window` turns SDL's `TextInput` into one `ETextInput` whose `charCode` is decoded from the first four bytes of the committed text (`sdl.Event.keyCode`). An IME commits a whole string at once (Japanese, Chinese, Korean input), and the game receives only its first character (HPS-38, found in Sprout SPR-386). SDL's composition (`SDL_EVENT_TEXT_EDITING`) never reaches the game either, so an application cannot show the text being composed, and it cannot tell the IME where to place its candidate window.

The `GeTechG/hashlink` SDL library delivers both: `sdl.Event.text` (UTF-8, the whole commit or the composition) with the new event type `TextEditing` (10), and `sdl.Window.setTextInputArea`. Upstream `HaxeFoundation/hashlink`, the library `tools/setup.sh` pins, has neither; the sources keep building and behaving as today with it.

## What Changes
- `hxd.EventKind.ETextEditing` and the `hxd.Event` fields `text`, `editCursor`, `editLength`: the current IME composition, sent to the window's event targets each time it changes, with an empty `text` when it ends.
- HashLink/SDL: a commit sends one `ETextInput` per code point of `sdl.Event.text`, in order. With a library without `text`, the first character is decoded from `keyCode` as before. SDL's `TextEditing` (matched by value) becomes `ETextEditing`.
- `hxd.Window.setTextInputArea(x, y, width, height, cursor)`: the rectangle the IME places its candidate window next to. HashLink/SDL calls `sdl.Window.setTextInputArea` when the library has it; elsewhere it does nothing.
- JS: `compositionupdate` / `compositionend` on the window's event element become `ETextEditing`; `compositionend` also sends one `ETextInput` per code point of the committed text. These events only fire when an editable element receives the IME input (an `<input>` or `contenteditable` under `globalEvents`); a bare canvas gets none.

## Capabilities

### New Capabilities
- `text-input`: how committed text and IME composition reach the game from `hxd.Window`.

### Modified Capabilities

## Impact
`hxd/Event.hx`, `hxd/Window.hx`, `hxd/Window.hl.hx`, `hxd/Window.js.hx`, the test `tests/TextInputTest.hx`. DirectX (`hldx`) is unchanged. `h2d`/`h3d` scenes do not route `ETextEditing` to the focused interactive yet: it goes to the window's event targets (`hxd.Window.addEventTarget`); routing is a follow-up issue.
