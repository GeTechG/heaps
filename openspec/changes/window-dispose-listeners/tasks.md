## 1. Implementation
- [ ] 1.1 `hxd/Window.js.hx`: make the anonymous and `.bind` listeners of the constructor methods, keeping what they do
- [ ] 1.2 `dispose`: remove everything the constructor added, in all three setups, and the drag and drop listeners; return early without a browser

## 2. Verification
- [ ] 2.1 A throwaway harness on a DOM stub under node: fails on the old `dispose`, passes on the new, for default canvas, custom canvas and `globalEvents`; a new window on the same canvas gets the events alone
- [ ] 2.2 `haxe all.hxml`, and a JS build of the window
