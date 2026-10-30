## ADDED Requirements

### Requirement: a game can stop and restart text input
`hxd.Window.stopTextInput()` SHALL turn text input off and `hxd.Window.startTextInput()` SHALL turn it back on; text input SHALL be on until `stopTextInput` is called. While it is off, the window SHALL send no `ETextInput` and SHALL NOT call `onTextEditing`, except to end a composition, and it SHALL keep sending `EKeyDown` and `EKeyUp`. A composition in progress when `stopTextInput` is called SHALL end with a call to `onTextEditing` with an empty text; on JS the browser may commit it first, and that commit SHALL still be sent. On HashLink/SDL they SHALL call `sdl.Window.stopTextInput` and `sdl.Window.startTextInput` when the SDL library provides them, by a typed call that dead code elimination keeps, and the library's `text_input` primitive otherwise. On JS, `stopTextInput` SHALL move the focus from the text input element to the canvas, or remove it under `globalEvents`, and `startTextInput` SHALL create the text input element if it does not exist and focus it unless another element of the page has the focus. On other platforms both SHALL do nothing.

#### Scenario: Never called
- **WHEN** the game calls neither `stopTextInput` nor `startTextInput`
- **THEN** text input behaves as if they did not exist

#### Scenario: Stopped on SDL
- **WHEN** the game has called `stopTextInput` and SDL delivers a `TextInput` event it had already queued
- **THEN** no `ETextInput` is sent

#### Scenario: Restarted on SDL
- **WHEN** the game has called `stopTextInput`, then `startTextInput`, and SDL delivers a `TextInput` event
- **THEN** its `ETextInput` events are sent

#### Scenario: Composition cut short on SDL
- **WHEN** the IME shows `にほ` and the game calls `stopTextInput`
- **THEN** `onTextEditing` is called with an empty text

#### Scenario: Leaving the text field on JS
- **WHEN** the text input element has the focus and the game calls `stopTextInput`
- **THEN** the canvas has the focus, neither `EFocus` nor `EFocusLost` is sent, and a key typed gives `EKeyDown` and `EKeyUp` but no `ETextInput`

#### Scenario: Clicking the canvas while stopped
- **WHEN** the game has called `stopTextInput` and the user clicks the canvas
- **THEN** the focus stays on the canvas

#### Scenario: Entering the text field on JS
- **WHEN** the canvas has the focus and the game calls `startTextInput`
- **THEN** the text input element has the focus, created if needed, and no `EFocus` or `EFocusLost` is sent

#### Scenario: A page's own input
- **WHEN** an input element of the page has the focus and the game calls `startTextInput`
- **THEN** that input keeps the focus

## MODIFIED Requirements

### Requirement: the window owns an editable element on JS
Browsers fire composition events only on a focused editable element, so on JS `hxd.Window` SHALL create a hidden `<textarea>`, its text input element, on the first call to `setTextInputArea` or `startTextInput`, and not before: a game that calls neither SHALL behave as without it. From then on, unless text input is stopped, the focus the canvas receives SHALL move on to the text input element, and focus passing between the canvas and the text input element SHALL send neither `EFocus` nor `EFocusLost`; under `globalEvents`, `setTextInputArea` SHALL focus it only when no other element has the focus. While text input is stopped, `setTextInputArea` SHALL only place it. Its key, composition, focus and blur events SHALL be handled as the canvas' are. Text it receives as an `input` of type `insertText` outside a composition SHALL be sent as one `ETextInput` per code point; a key typed on a keyboard SHALL give one `ETextInput`, not two. `dispose()` SHALL remove it.

#### Scenario: IME on the default canvas
- **WHEN** the game has called `setTextInputArea`, the canvas has the focus and an IME composes `にほん` then commits `日本`
- **THEN** `onTextEditing` is called with the composition, then with an empty text, and two `ETextInput` events are sent, `日` then `本`

#### Scenario: No call, no change
- **WHEN** the game calls neither `setTextInputArea` nor `startTextInput`
- **THEN** no element is added to the page and the canvas keeps the focus

#### Scenario: Clicking the canvas
- **WHEN** the text input element has the focus and the user clicks the canvas
- **THEN** the focus returns to the text input element and no `EFocusLost` is sent

#### Scenario: Placing while stopped
- **WHEN** the game has called `stopTextInput` and the canvas has the focus and the game calls `setTextInputArea`
- **THEN** the text input element is placed over the rectangle and the canvas keeps the focus
