# gl-context-reset Specification

## Purpose
How `h3d.impl.GlDriver` on HashLink recovers when the GL context is replaced by a new one.

## Requirements

### Requirement: a replaced GL context is recovered on HashLink
On HashLink, `h3d.impl.GlDriver.onContextReset()` SHALL treat every GL object of the driver as gone: it SHALL forget the compiled programs without deleting them, reset its cached GL state (bound shader, buffers, textures, render targets, material, stencil and color mask state, vertex attributes and divisors), recreate its own framebuffer and vertex array and the pixel store and seamless cube map state, and then run the engine's `onCreate(true)` path: `Allocator.onContextLost`, `MemoryManager.onContextLost`, a resize and `Engine.onContextLost`. A texture with `realloc` SHALL be reallocated and refilled the next time it is used. Before the engine has been created the call SHALL only reset the driver's state. `hxd.Window` SHALL call it on SDL's `RenderDeviceReset` (event type 700, matched by value) when the current engine's driver is a `GlDriver`.

#### Scenario: Render device reset
- **WHEN** SDL delivers `RenderDeviceReset` for a running engine
- **THEN** `Engine.onContextLost` is called, and the next frame draws with textures and buffers of the new context and no GL error

#### Scenario: Texture with realloc
- **WHEN** a texture with `realloc` is used after the reset
- **THEN** it is allocated in the new context and `realloc` is called
