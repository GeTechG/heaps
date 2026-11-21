# Proposal

## Why

Tools that check and serialize HXSL blocks in Haxe macros need the shader import resolver used by ordinary shader classes. The public checker currently requires callers to supply a resolver, so tools that want the standard behavior depend on private methods.

## What Changes

- Add `hxsl.Macros.checkShader(name, shader)` to check a parsed HXSL block using standard shader imports.
- Cover the API from an external macro that imports a Heaps shader and checks import diagnostics.

## Capabilities

### New Capabilities

- `hxsl-macro-check` covers checking HXSL blocks and resolving their shader imports from Haxe macros.

### Modified Capabilities

## Impact

The public API is additive in `hxsl/Macros.hx`. The regression test runs from the repository's `tests/` directory.
