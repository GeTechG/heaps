# gl-driver-gles Specification

## Purpose
On a native OpenGL ES context `h3d.impl.GlDriver` issues only calls OpenGL ES accepts: no `GL_INVALID_ENUM` from desktop-only state, no `GL_INVALID_OPERATION` from a uniform upload larger than its array.

## Requirements

### Requirement: no desktop-only state on a native OpenGL ES context
On a native target, when the context's `GL_VERSION` string reports OpenGL ES, `h3d.impl.GlDriver` SHALL NOT pass to the context an enum that OpenGL ES 3.0 does not define: it SHALL NOT enable `TEXTURE_CUBE_MAP_SEAMLESS`, SHALL NOT set the `TEXTURE_LOD_BIAS` texture parameter, and SHALL NOT enable or disable `DEPTH_CLAMP` unless the context lists `GL_EXT_depth_clamp`, which defines that enum for OpenGL ES. On a desktop OpenGL context all three SHALL be used as before.

#### Scenario: Driver start on OpenGL ES 3.0
- **WHEN** the driver is created on a context whose version string is `OpenGL ES 3.0 …`
- **THEN** no `glEnable(TEXTURE_CUBE_MAP_SEAMLESS)` is issued and the GL error queue stays empty

#### Scenario: Sampler state on OpenGL ES
- **WHEN** a texture is bound for drawing on an OpenGL ES context
- **THEN** its filter, wrap and base level are set and `TEXTURE_LOD_BIAS` is not

#### Scenario: Depth clamp on OpenGL ES
- **WHEN** a pass with `depthClamp` is drawn, or `setDepthClamp` is called, on an OpenGL ES context that does not list `GL_EXT_depth_clamp`
- **THEN** no `DEPTH_CLAMP` state change is issued and `hasFeature(DepthClamp)` is false

#### Scenario: Desktop OpenGL
- **WHEN** the driver runs on a desktop OpenGL context
- **THEN** seamless cube maps are enabled, the LOD bias is set and depth clamp is available

### Requirement: extension state on a native OpenGL ES context follows the extension list
On a native OpenGL ES context `h3d.impl.GlDriver` SHALL use state that OpenGL ES defines only through an extension when, and only when, the context lists that extension. Where the SDL binding has an extension query (hlsdl 1.15.0 or later) the driver SHALL ask it once, when the driver is created, with the `GL_`-prefixed name:
- `GL_EXT_texture_filter_anisotropic`: without it the `TEXTURE_MAX_ANISOTROPY_EXT` texture parameter SHALL NOT be set.
- `GL_EXT_depth_clamp`: with it depth clamp SHALL be available — `hasFeature(DepthClamp)` is true, and `setDepthClamp` and the pass `depthClamp` bit enable or disable `DEPTH_CLAMP`; without it `hasFeature(DepthClamp)` SHALL be false and no `DEPTH_CLAMP` state change SHALL be issued.

With an older hlsdl, which has no extension query, the driver SHALL set the anisotropy parameter and SHALL report depth clamp as unsupported on OpenGL ES. On a desktop OpenGL context the anisotropy parameter and depth clamp SHALL be used without a query.

#### Scenario: OpenGL ES without anisotropic filtering
- **WHEN** a texture is bound for drawing on an OpenGL ES context that does not list `GL_EXT_texture_filter_anisotropic`
- **THEN** `TEXTURE_MAX_ANISOTROPY_EXT` is not set and the GL error queue stays empty

#### Scenario: OpenGL ES with anisotropic filtering
- **WHEN** a texture with an anisotropic filter is bound on an OpenGL ES context that lists `GL_EXT_texture_filter_anisotropic`
- **THEN** `TEXTURE_MAX_ANISOTROPY_EXT` is set to the texture's `anisotropicMaxLevel`

#### Scenario: OpenGL ES with depth clamp
- **WHEN** `setDepthClamp(true)` is called on an OpenGL ES context that lists `GL_EXT_depth_clamp`
- **THEN** `DEPTH_CLAMP` is enabled and `hasFeature(DepthClamp)` is true

#### Scenario: Extensions are queried once
- **WHEN** textures are bound and passes drawn after the driver is created
- **THEN** the extension list is not queried again

#### Scenario: Desktop OpenGL
- **WHEN** the driver runs on a desktop OpenGL context
- **THEN** the anisotropy parameter is set and depth clamp is available

### Requirement: a uniform array upload names the array's own element count
On a native target, when `h3d.impl.GlDriver` uploads the globals or the params of a shader, the count it passes to `glUniform4fv` SHALL be the number of `vec4` in the uniform array — the shader's `globalsSize` or `paramsSize` — and the data it passes SHALL hold that many `vec4`. It SHALL NOT pass the number of floats.

#### Scenario: Params upload on OpenGL ES
- **WHEN** a shader whose `paramsSize` is 1 is drawn on an OpenGL ES context
- **THEN** `glUniform4fv` is called with a count of 1 and the GL error queue stays empty

#### Scenario: Globals upload
- **WHEN** a shader whose `globalsSize` is N is drawn on a native target
- **THEN** `glUniform4fv` is called for the globals with a count of N, over N * 16 bytes of data

#### Scenario: Desktop OpenGL
- **WHEN** the same scene is drawn on a desktop OpenGL context
- **THEN** the uniform arrays receive the same values as before
