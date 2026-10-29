## Why
On HashLink/SDL `hxd.Window` turns SDL's `TextInput` into one `ETextInput` whose `charCode` is decoded from the first four bytes of the committed text (`sdl.Event.keyCode`). An IME commits a whole string at once (Japanese, Chinese, Korean input), and the game receives only its first character (HPS-38, found in Sprout SPR-386). SDL's composition (`SDL_EVENT_TEXT_EDITING`) never reaches the game either, so an application cannot show the text being composed, and it cannot tell the IME where to place its candidate window.

The `GeTechG/hashlink` SDL library delivers both: `sdl.Event.text` (UTF-8, the whole commit or the composition) with the new event type `TextEditing` (10), and `sdl.Window.setTextInputArea`. Upstream `HaxeFoundation/hashlink`, the library `tools/setup.sh` pins, has neither; the sources keep building and behaving as today with it.

## What Changes
- `hxd.Window.onTextEditing(text, cursor, length)`, a dynamic callback like `onClose`: the current IME composition, called each time it changes, with an empty `text` when it ends. It is not a new `hxd.EventKind`: `h2d.Interactive`, `h3d.scene.Interactive` and applications switch over `EventKind` exhaustively, and a new constructor breaks them; the scenes have no notion of a composition to route either.
- HashLink/SDL: a commit sends one `ETextInput` per code point of `sdl.Event.text`, in order. With a library without `text`, the first character is decoded from `keyCode` as before. SDL's `TextEditing` (matched by value) calls `onTextEditing`. Whether the library has `sdl.Event.text` and `sdl.Window.setTextInputArea` is decided at compile time (a macro that looks the field up), so the calls are typed and survive `-dce full`.
- `hxd.Window.setTextInputArea(x, y, width, height, cursor)`: the rectangle the IME places its candidate window next to. HashLink/SDL calls `sdl.Window.setTextInputArea` when the library has it; elsewhere it does nothing.
- JS: `compositionupdate` / `compositionend` on the window's event element call `onTextEditing`; `compositionend` also sends one `ETextInput` per code point of the committed text. These events only fire when an editable element receives the IME input (an `<input>` or `contenteditable` under `globalEvents`); a bare canvas gets none.

## Capabilities

### New Capabilities
- `text-input`: how committed text and IME composition reach the game from `hxd.Window`.

### Modified Capabilities

## Impact
`hxd/Event.hx`, `hxd/Window.hx`, `hxd/Window.hl.hx`, `hxd/Window.js.hx`, the test `tests/TextInputTest.hx`. DirectX (`hldx`) is unchanged.
