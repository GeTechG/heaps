## Why
On a native OpenGL ES 3 context (HashLink/SDL on Android) `h3d.impl.GlDriver` passes three enums that exist only in desktop OpenGL: `glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS)` at init, `glEnable` / `glDisable(GL_DEPTH_CLAMP)` on a depth-clamp state change, and `glTexParameterf(GL_TEXTURE_LOD_BIAS)` on every sampler state change. Each raises `GL_INVALID_ENUM`. The picture is unaffected, but the errors stay in the GL error queue and fill the device log on every run.

## What Changes
- `GlDriver`, native targets, context reports an `ES` version: cube-map seamless filtering is not enabled (it is always on in ES 3), the texture LOD bias parameter is not set, and depth clamp is reported as unsupported (`hasFeature(DepthClamp)` is false, `setDepthClamp` and the pass `depthClamp` bit do nothing) — as the JS target already does without `EXT_depth_clamp`.
- Desktop OpenGL and the JS target are untouched.

## Capabilities

### New Capabilities
- `gl-driver-gles`: which desktop-only OpenGL state `h3d.impl.GlDriver` leaves alone on a native OpenGL ES context.

### Modified Capabilities

## Impact
`h3d/impl/GlDriver.hx` only. On native ES `h3d.mat.Texture.lodBias` has no effect (it had none before: the call was rejected), and depth clamp is unavailable even where the device has `EXT_depth_clamp` — the SDL binding has no extension query to tell.
