# Proposal

## Why

An editor that recompiles HXSL from text replaces a shader with a new `SharedShader` on every save. Every replacement leaves its linked `RuntimeShader`s in `hxsl.Cache` (~29 KiB each, even for unchanged text), and every new text leaves a GL program in `GlDriver` that is only freed with the context. Neither the cache nor the driver offers a way to forget a shader; upstream Heaps has none either (`SharedShader.reloadShader` evicts nothing).

## What Changes

- New `hxsl.Cache.evict(shader : SharedShader, ?driver : h3d.impl.Driver)`: forgets every runtime shader linked from an instance of `shader` (and the batch shaders made from them), keeps the signature table pointing at a live shader, and asks the driver to release the compiled program of every runtime shader id that no remaining shader shares. Without a driver argument the current engine's driver is used, if any.
- New `h3d.impl.Driver.disposeShader(shader : hxsl.RuntimeShader)`, a no-op by default; `GlDriver` deletes the program, `RenderGraphDriver` forwards it.
- `hxsl.Cache.SearchMap` gains removal.

## Capabilities

### New Capabilities
- `shader-cache`: how `hxsl.Cache` and the drivers forget the shaders linked from a `SharedShader` that is no longer used.

### Modified Capabilities

## Impact

`hxsl/Cache.hx`, `h3d/impl/Driver.hx`, `h3d/impl/GlDriver.hx`, `h3d/impl/RenderGraphDriver.hx`, a new test `tests/ShaderEvictTest.hx`. Additive API; no behaviour changes for code that never calls `evict`. DirectX, DX12 and Vulkan keep the default no-op: their compiled shaders stay until the context goes.
