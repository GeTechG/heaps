## 1. Implementation

- [x] 1.1 `hxd.Window` (generic): `startTextInput` / `stopTextInput`, doing nothing
- [x] 1.2 `hxd.Window` (HashLink/SDL): the two calls through `sdl.Window` when the library has them, the `text_input` primitive otherwise; no `ETextInput` or `onTextEditing` while stopped, a composition cut short ends with an empty `onTextEditing`
- [x] 1.3 `hxd.Window` (JS): the two calls, the focus rules, `keypress` and composition events ignored while stopped, `setTextInputArea` only places while stopped

## 2. Verification

- [x] 2.1 `haxe all.hxml` builds
- [x] 2.2 in headless Chromium (Playwright, IME driven through the DevTools protocol), with the default canvas and with `globalEvents`: every JS scenario of the spec
- [x] 2.3 on HashLink, with the pinned library and with a library that has `sdl.Window.stopTextInput` if one is at hand: the SDL scenarios of the spec from synthetic `sdl.Event`s, and the two calls return
- [ ] 2.4 [human] on a phone or tablet with a virtual keyboard: the keyboard opens when the game enters its text field and closes when the game leaves it
