# gl-context-reset Specification

## Purpose
How `h3d.impl.GlDriver` on HashLink recovers when the GL context is replaced by a new one.

## Requirements

### Requirement: a replaced GL context is recovered on HashLink
On HashLink, `h3d.impl.GlDriver.onContextReset()` SHALL treat every GL object of the driver as gone: it SHALL forget the compiled programs without deleting them, reset its cached GL state, recreate its own framebuffer and vertex array and the pixel store and seamless cube map state, then run the engine's `onCreate(true)` path. A texture with `realloc` SHALL be reallocated and refilled the next time it is used. Before the engine has been created the call SHALL only reset the driver's state.

#### Scenario: Cached state is forgotten
- **WHEN** `onContextReset()` is called
- **THEN** the driver no longer assumes any bound shader, buffer, texture, render target, material, stencil or color mask state, vertex attribute or divisor, so the next draw sets each of them again

#### Scenario: The engine's recovery path
- **WHEN** `onContextReset()` is called for a created engine
- **THEN** `Allocator.onContextLost`, `MemoryManager.onContextLost`, a resize and `Engine.onContextLost` run, as in `onCreate(true)`

#### Scenario: Texture with realloc
- **WHEN** a texture with `realloc` is used after the reset
- **THEN** it is allocated in the new context and `realloc` is called

#### Scenario: Before the engine exists
- **WHEN** `onContextReset()` is called before the engine has been created
- **THEN** only the driver's state is reset and no `onContextLost` is called

### Requirement: SDL's render device reset triggers the recovery
`hxd.Window` on HashLink/SDL SHALL call `GlDriver.onContextReset()` on SDL's `RenderDeviceReset` (event type 700, matched by value) when the current engine's driver is a `GlDriver`.

#### Scenario: Render device reset
- **WHEN** SDL delivers `RenderDeviceReset` for a running engine
- **THEN** `Engine.onContextLost` is called, and the next frame draws with textures and buffers of the new context and no GL error

#### Scenario: Another driver
- **WHEN** SDL delivers `RenderDeviceReset` and the current engine's driver is not a `GlDriver`
- **THEN** `onContextReset` is not called
