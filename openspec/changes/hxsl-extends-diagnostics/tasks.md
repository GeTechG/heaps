# Tasks

## 1. Position the non-shader extension error

- [ ] 1.1 Convert string failures when loading an `@:extends` target to positioned HXSL errors and document the public macro diagnostic. Compile the shader class reproducer from HPS-53 and check that the error underlines the `String` argument.
- [ ] 1.2 Extend `tests/HxslMacroCheckTest.hx` to assert the diagnostic message and argument position for a parsed block. Run the test command at the top of the file with the pinned Haxe.
