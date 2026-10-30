## Why
Once text input is on, a game cannot turn it off. On JS, the hidden textarea created by `setTextInputArea` keeps the focus for good, so on a touch device the virtual keyboard can stay open after the game leaves its text field (HPS-40, follow-up of HPS-39). HashLink/SDL has the same gap: the SDL library starts text input when it creates a window and nothing stops it, so the IME stays active and an on-screen keyboard stays up.

## What Changes
- `hxd.Window.stopTextInput()` and `hxd.Window.startTextInput()`. Text input stays on by default: a game that never calls them behaves as today.
- While stopped, the window sends no `ETextInput` and does not call `onTextEditing`; `EKeyDown` and `EKeyUp` keep coming. A composition in progress when `stopTextInput` is called ends with `onTextEditing("")`.
- HashLink/SDL: `sdl.Window.stopTextInput` / `startTextInput` when the SDL library provides them (`GeTechG/hashlink`, per window), decided at compile time as `setTextInputArea` is; otherwise the library's `text_input` primitive, which every version has and which applies to all its windows. Events SDL had already queued when the game stopped are dropped.
- JS, `stopTextInput`: the textarea gives up the focus, to the canvas (to nothing under `globalEvents`), which closes a virtual keyboard, and the focus the canvas receives stays there. The focus passing sends neither `EFocus` nor `EFocusLost`. Without a textarea, none is created.
- JS, `startTextInput`: creates the textarea if it does not exist yet, so a game can ask for the keyboard without placing a candidate window, and focuses it unless another element of the page has the focus. Browsers open a virtual keyboard only for a focus given during a user gesture (iOS Safari strictly): a game calls it from the input event that enters the text field.
- JS, `setTextInputArea` while stopped: places the textarea (creating it if needed) and leaves the focus alone.
- DirectX (`hldx`) and the generic `hxd.Window`: both calls do nothing. DirectX has no IME path here, as in the earlier changes.

The name pair follows SDL's and the issue's suggestion rather than a `textInput : Bool` property: starting has effects a property set would hide (a keyboard opens, an element is created).

## Capabilities

### New Capabilities

### Modified Capabilities
- `text-input`: a game can stop and restart text input; the JS textarea's creation and focus rules take that into account.

## Impact
`hxd/Window.hx`, `hxd/Window.hl.hx`, `hxd/Window.js.hx`. `tests/TextInputTest.hx` is outside this task's footprint and is not changed: verification runs from throwaway harnesses.
