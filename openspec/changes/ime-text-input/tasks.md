## 1. Implementation

- [ ] 1.1 `hxd.Event`: `ETextEditing`, fields `text`, `editCursor`, `editLength`, helpers that turn a committed string into one `ETextInput` per code point and a composition into an `ETextEditing`
- [ ] 1.2 `hxd.Window` (HashLink/SDL): commit from `sdl.Event.text` when the library has it, `TextEditing` (10) to `ETextEditing`, `setTextInputArea` through `sdl.Window.setTextInputArea` when the library has it
- [ ] 1.3 `hxd.Window` (JS): `compositionupdate` / `compositionend`; `setTextInputArea` does nothing; the generic `hxd.Window` gets the no-op too

## 2. Verification

- [ ] 2.1 `tests/TextInputTest.hx` (interp): a commit of several code points, one outside the BMP, gives one `ETextInput` each in order; a composition gives `ETextEditing` with its text, cursor and length; an empty composition ends it
- [ ] 2.2 the HashLink path run against the `GeTechG/hashlink` SDL library: an `sdl.Event` carrying a multi-character `text` yields one `ETextInput` per code point, type 10 yields `ETextEditing`, `setTextInputArea` reaches the library; with a library without them it compiles and falls back
- [ ] 2.3 `haxe all.hxml` builds
