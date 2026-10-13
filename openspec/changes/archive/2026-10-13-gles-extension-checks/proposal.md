## Why
`gles-invalid-enums` (HPS-19) assumed the SDL binding cannot query a GL extension, so on a native OpenGL ES context it turned depth clamp off for good and left `GL_TEXTURE_MAX_ANISOTROPY_EXT` sent unconditionally. The assumption is wrong: `sdl.GL.hasExtension(name)` exists since hlsdl 1.15.0 and `GlDriver` already uses it for `GL_ARB_indirect_parameters`. As a result a device without `GL_EXT_texture_filter_anisotropic` gets `GL_INVALID_ENUM` on every sampler state change, and a device with `GL_EXT_depth_clamp` is denied depth clamp.

## What Changes
- `GlDriver`, native target, context reports an `ES` version, hlsdl 1.15.0 or later: `GL_EXT_texture_filter_anisotropic` and `GL_EXT_depth_clamp` are queried once, when the driver is created.
  - Without the first, `TEXTURE_MAX_ANISOTROPY_EXT` is not set on a texture.
  - With the second, depth clamp is available: `hasFeature(DepthClamp)` is true, `setDepthClamp` and the pass `depthClamp` bit change `DEPTH_CLAMP` (the `EXT` enum has the desktop value, 0x864F). Without it, depth clamp stays unsupported.
- hlsdl older than 1.15.0 (no `hasExtension`): as before — the anisotropy parameter is set, depth clamp is unsupported on ES.
- Desktop OpenGL and the JS target are untouched.

## Capabilities

### New Capabilities

### Modified Capabilities
- `gl-driver-gles`: depth clamp on a native OpenGL ES context is no longer unconditionally off, it follows `GL_EXT_depth_clamp`; a new requirement gates the anisotropy texture parameter on `GL_EXT_texture_filter_anisotropic`.

## Impact
`h3d/impl/GlDriver.hx` only. On an ES device with `GL_EXT_depth_clamp`, `hasFeature(DepthClamp)` turns true, so code that asks for depth clamp (e.g. shadow passes) now gets it there.
