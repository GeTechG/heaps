## Why
Browsers fire `compositionstart` / `compositionupdate` / `compositionend` only on an editable element (`<input>`, `<textarea>`, `contenteditable`) that holds the focus. `hxd.Window` on JS listens for them on its event element, by default the canvas, which is not editable: an IME there delivers nothing but `keydown` with `keyCode` 229, so Japanese, Chinese and Korean input does not work on JS (HPS-39, follow-up of HPS-38). `setTextInputArea` does nothing on JS, so the browser's candidate window cannot follow the game's text field either.

## What Changes
- JS: `hxd.Window` owns a hidden `<textarea>` (transparent, no pointer events, no autocorrect or spellcheck) appended to the document body. It is created by the first call to `setTextInputArea`: a game that never calls it keeps today's behaviour exactly, and no virtual keyboard opens on a touch device for a game that does not edit text.
- `setTextInputArea(x, y, width, height, cursor)` places the textarea over that rectangle of the canvas (window pixels converted to CSS pixels, its left edge at `x + cursor`, its font size the height), so the browser puts the candidate window next to the text cursor.
- Focus: while the textarea exists, the focus the canvas receives moves on to the textarea, and `setTextInputArea` moves it there when the canvas has it. Under `globalEvents`, `setTextInputArea` focuses the textarea when no other element has the focus (the page's own inputs keep theirs). Focus passing between the canvas and the textarea sends neither `EFocus` nor `EFocusLost`.
- Without `globalEvents`, the textarea's `keydown`, `keyup`, `keypress`, composition, `focus` and `blur` events are handled as the canvas' are; under `globalEvents` they bubble to the window, which already handles them.
- Text the textarea receives as plain `input` (`inputType` `insertText`, outside a composition — a touch keyboard, dictation) is sent as `ETextInput` events, one per code point. The textarea's own default for `keypress` is prevented, so a key typed on a desktop keyboard gives one `ETextInput`, not two. The textarea is emptied after every commit and every such input.
- `dispose()` removes the textarea.

There is no call to stop text input: like HashLink/SDL, where SDL's text input stays on, the textarea keeps the focus once created.

## Capabilities

### New Capabilities

### Modified Capabilities
- `text-input`: on JS the composition and the commit come from an editable element the window owns, and `setTextInputArea` places the candidate window.

## Impact
`hxd/Window.js.hx` only. HashLink and the generic `hxd.Window` are unchanged.
