# gl-driver-gles Specification

## Purpose
On a native OpenGL ES context `h3d.impl.GlDriver` issues only calls OpenGL ES defines: no `GL_INVALID_ENUM` from desktop-only state.

## Requirements

### Requirement: no desktop-only state on a native OpenGL ES context
On a native target, when the context's `GL_VERSION` string reports OpenGL ES, `h3d.impl.GlDriver` SHALL NOT pass to the context an enum that OpenGL ES 3.0 does not define: it SHALL NOT enable `TEXTURE_CUBE_MAP_SEAMLESS`, SHALL NOT set the `TEXTURE_LOD_BIAS` texture parameter, and SHALL NOT enable or disable `DEPTH_CLAMP`. Depth clamp SHALL be reported as unsupported there: `hasFeature(DepthClamp)` is false. On a desktop OpenGL context all three SHALL be used as before.

#### Scenario: Driver start on OpenGL ES 3.0
- **WHEN** the driver is created on a context whose version string is `OpenGL ES 3.0 …`
- **THEN** no `glEnable(TEXTURE_CUBE_MAP_SEAMLESS)` is issued and the GL error queue stays empty

#### Scenario: Sampler state on OpenGL ES
- **WHEN** a texture is bound for drawing on an OpenGL ES context
- **THEN** its filter, wrap and base level are set and `TEXTURE_LOD_BIAS` is not

#### Scenario: Depth clamp on OpenGL ES
- **WHEN** a pass with `depthClamp` is drawn, or `setDepthClamp` is called, on an OpenGL ES context
- **THEN** no `DEPTH_CLAMP` state change is issued and `hasFeature(DepthClamp)` is false

#### Scenario: Desktop OpenGL
- **WHEN** the driver runs on a desktop OpenGL context
- **THEN** seamless cube maps are enabled, the LOD bias is set and depth clamp is available
