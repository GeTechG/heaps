# Proposal

## Why

When an HXSL block uses `@:extends` with a Haxe type that has no shader source, the compiler reports an uncaught exception in the macro. Shader authors need the error at the type that they named.

## What Changes

- Report a non-shader type in `@:extends` as a Haxe compiler error at the directive's argument.
- Cover the diagnostic in the shader class build and the parsed HXSL macro entry point.

## Capabilities

### Modified Capabilities

- `hxsl-macro-check` specifies the positioned diagnostic for a non-shader `@:extends` target.

## Impact

HXSL shader checking and compiler diagnostics in Haxe macros.
