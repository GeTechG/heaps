## ADDED Requirements

### Requirement: a commit reaches the game whole
When the platform commits text, `hxd.Window` SHALL send one `ETextInput` event per Unicode code point of the committed text, in order, each with that code point in `charCode`. On HashLink/SDL the committed text SHALL be read from `sdl.Event.text` (UTF-8) when the SDL library provides it; with a library that does not, a single `ETextInput` SHALL be decoded from `sdl.Event.keyCode`, and the sources SHALL build with it.

#### Scenario: IME commit of several characters
- **WHEN** an IME commits `日本語` in one SDL `TextInput` event
- **THEN** three `ETextInput` events are sent, with the code points of `日`, `本` and `語` in that order

#### Scenario: Character outside the BMP
- **WHEN** the committed text is `a😀`
- **THEN** two `ETextInput` events are sent, with `charCode` 0x61 then 0x1F600

### Requirement: the composition reaches the game
While an IME composes text, `hxd.Window` SHALL send an `ETextEditing` event to its event targets each time the composition changes, with the whole composition in `text`, the cursor or selection start in `editCursor` and the selection length in `editLength` (code points; -1 when the platform does not give one). When the composition ends, committed or cancelled, an `ETextEditing` with an empty `text` SHALL be sent. On HashLink/SDL these come from SDL's `TextEditing` event, matched by its numeric value (10) so that the sources build with an SDL library that does not define it. On JS they come from `compositionupdate` and `compositionend` on the window's event element; `compositionend` SHALL also send the committed text as `ETextInput` events.

#### Scenario: Composing
- **WHEN** the IME shows `にほ` with the cursor after it
- **THEN** an `ETextEditing` is sent with `text` `にほ` and `editCursor` 2

#### Scenario: Composition ends
- **WHEN** the user commits or cancels the composition
- **THEN** an `ETextEditing` with an empty `text` is sent

### Requirement: the candidate window follows the text field
`hxd.Window.setTextInputArea(x, y, width, height, cursor)` SHALL tell the platform's IME the rectangle, in window coordinates, next to which it places its candidate window, `cursor` being the offset of the text cursor from `x`. On HashLink/SDL it SHALL call `sdl.Window.setTextInputArea` when the SDL library provides it and do nothing otherwise; on other platforms it SHALL do nothing.

#### Scenario: Library without the call
- **WHEN** `setTextInputArea` is called with an SDL library that has no `setTextInputArea`
- **THEN** nothing happens and no error is raised
