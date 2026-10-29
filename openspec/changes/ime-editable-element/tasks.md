## 1. Implementation

- [ ] 1.1 `hxd.Window` (JS): the hidden textarea, created by `setTextInputArea`, placed over the given rectangle, removed by `dispose`
- [ ] 1.2 focus moved from the canvas to the textarea, no `EFocus` / `EFocusLost` for focus passing between them; under `globalEvents` the textarea is focused only when nothing else has the focus
- [ ] 1.3 textarea events: key and composition events as the canvas' (without `globalEvents`), `input` of `insertText` to `ETextInput`, no default for `keypress`, emptied after a commit

## 2. Verification

- [ ] 2.1 `haxe all.hxml` builds
- [ ] 2.2 in headless Chromium (Playwright, IME driven through the DevTools protocol `Input.imeSetComposition` / `Input.insertText`), a page with the default canvas: before `setTextInputArea` nothing changes; after it, a composition calls `onTextEditing` with the text and then an empty text, the commit gives one `ETextInput` per code point, a plain key gives one `ETextInput`, clicking the canvas leaves the focus in the textarea without `EFocusLost`, the textarea sits over the given rectangle; the same with `globalEvents`
- [ ] 2.3 [human] in a desktop browser with a real Japanese (or Chinese/Korean) IME, on a sample that calls `setTextInputArea`: typing composes and commits into the game, and the candidate window opens next to the given rectangle
