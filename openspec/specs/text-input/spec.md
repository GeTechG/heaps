# text-input Specification

## Purpose
How committed text and the IME composition reach the game from `hxd.Window`, and how the game tells the IME where the text field is.

## Requirements

### Requirement: a commit reaches the game whole
When the platform commits text, `hxd.Window` SHALL send one `ETextInput` event per Unicode code point of the committed text, in order, each with that code point in `charCode`. On HashLink/SDL the committed text SHALL be read from `sdl.Event.text` (UTF-8) when the SDL library provides it; with a library that does not, a single `ETextInput` SHALL be decoded from `sdl.Event.keyCode`, and the sources SHALL build with it.

#### Scenario: IME commit of several characters
- **WHEN** an IME commits `日本語` in one SDL `TextInput` event
- **THEN** three `ETextInput` events are sent, with the code points of `日`, `本` and `語` in that order

#### Scenario: Character outside the BMP
- **WHEN** the committed text is `a😀`
- **THEN** two `ETextInput` events are sent, with `charCode` 0x61 then 0x1F600

### Requirement: the composition reaches the game
While an IME composes text, `hxd.Window` SHALL call its dynamic `onTextEditing(text, cursor, length)` each time the composition changes, with the whole composition in `text`, the cursor or selection start in `cursor` and the selection length in `length` (code points; -1 when the platform does not give one). When the composition ends, committed or cancelled, it SHALL be called with an empty `text`. The composition SHALL NOT be sent as an `hxd.Event`, so that exhaustive switches over `hxd.EventKind` keep compiling. On HashLink/SDL these come from SDL's `TextEditing` event, matched by its numeric value (10) so that the sources build with an SDL library that does not define it. On JS they come from `compositionupdate` and `compositionend` on the window's event element or on its text input element (see *the window owns an editable element on JS*); `compositionend` SHALL also send the committed text as `ETextInput` events.

#### Scenario: Composing
- **WHEN** the IME shows `にほ` with the cursor after it
- **THEN** `onTextEditing` is called with `にほ` and cursor 2

#### Scenario: Composition ends
- **WHEN** the user commits or cancels the composition
- **THEN** `onTextEditing` is called with an empty text

### Requirement: the candidate window follows the text field
`hxd.Window.setTextInputArea(x, y, width, height, cursor)` SHALL tell the platform's IME the rectangle, in window coordinates, next to which it places its candidate window, `cursor` being the offset of the text cursor from `x`. On HashLink/SDL it SHALL call `sdl.Window.setTextInputArea` when the SDL library provides it, by a typed call that dead code elimination keeps, and do nothing otherwise. On JS it SHALL place the window's text input element over that rectangle of the canvas, its left edge at `x + cursor`. On other platforms it SHALL do nothing.

#### Scenario: Library without the call
- **WHEN** `setTextInputArea` is called with an SDL library that has no `setTextInputArea`
- **THEN** nothing happens and no error is raised

#### Scenario: JS
- **WHEN** `setTextInputArea(100, 40, 200, 20, 30)` is called on JS with a device pixel ratio of 1
- **THEN** the text input element's top-left corner is 130, 40 CSS pixels from the canvas' top-left corner

### Requirement: the window owns an editable element on JS
Browsers fire composition events only on a focused editable element, so on JS `hxd.Window` SHALL create a hidden `<textarea>`, its text input element, on the first call to `setTextInputArea`, and not before: a game that never calls it SHALL behave as without it. From then on, the focus the canvas receives SHALL move on to the text input element, and focus passing between the canvas and the text input element SHALL send neither `EFocus` nor `EFocusLost`; under `globalEvents`, `setTextInputArea` SHALL focus it only when no other element has the focus. Its key, composition, focus and blur events SHALL be handled as the canvas' are. Text it receives as an `input` of type `insertText` outside a composition SHALL be sent as one `ETextInput` per code point; a key typed on a keyboard SHALL give one `ETextInput`, not two. `dispose()` SHALL remove it.

#### Scenario: IME on the default canvas
- **WHEN** the game has called `setTextInputArea`, the canvas has the focus and an IME composes `にほん` then commits `日本`
- **THEN** `onTextEditing` is called with the composition, then with an empty text, and two `ETextInput` events are sent, `日` then `本`

#### Scenario: No call, no change
- **WHEN** the game never calls `setTextInputArea`
- **THEN** no element is added to the page and the canvas keeps the focus

#### Scenario: Clicking the canvas
- **WHEN** the text input element has the focus and the user clicks the canvas
- **THEN** the focus returns to the text input element and no `EFocusLost` is sent
