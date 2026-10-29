## 1. Implementation

- [x] 1.1 `hxd.Event`: a helper that turns a committed string into one `ETextInput` per code point; a macro that compiles code only when a library class has a field
- [x] 1.2 `hxd.Window` (HashLink/SDL): `onTextEditing`; commit from `sdl.Event.text` when the library has it, `TextEditing` (10) to `onTextEditing`, `setTextInputArea` through `sdl.Window.setTextInputArea` when the library has it
- [x] 1.3 `hxd.Window` (JS): `compositionupdate` / `compositionend`; `setTextInputArea` does nothing; the generic `hxd.Window` gets the no-op too

## 2. Verification

- [x] 2.1 `tests/TextInputTest.hx` (interp): a commit of several code points, one outside the BMP, gives one `ETextInput` each in order
- [x] 2.2 the same test on HashLink against the `GeTechG/hashlink` SDL library: an `sdl.Event` carrying a multi-character `text` yields one `ETextInput` per code point, type 10 calls `onTextEditing` with the composition then an empty one, `setTextInputArea` reaches the library; with the pinned upstream library it compiles (its fallback is the unchanged `keyCode` decoding)
- [x] 2.3 `haxe all.hxml` builds
