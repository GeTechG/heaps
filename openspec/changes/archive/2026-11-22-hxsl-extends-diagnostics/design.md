# Design

## Context

The shader class build and `hxsl.Macros.checkShader` use the same checker and shader loader. The loader throws a string for types with no shader source. The checker currently handles HXSL errors from loading an `@:extends` target.

## Decisions

- Convert the loader's string exception to an HXSL error at the `@:extends` argument, alongside the existing HXSL error handler. Both macro entry points already translate positioned HXSL errors to Haxe errors.
- Keep the handler specific to the thrown string so Haxe type-resolution errors continue to propagate with their existing messages and positions.
