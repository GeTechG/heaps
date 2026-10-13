## 1. Implementation

- [ ] 1.1 `h3d.impl.GlDriver`, native ES context, hlsdl >= 1.15.0: query `GL_EXT_texture_filter_anisotropic` and `GL_EXT_depth_clamp` once in the constructor; set `TEXTURE_MAX_ANISOTROPY_EXT` only with the first, set `hasDepthClamp` from the second

## 2. Verification

- [ ] 2.1 `haxe all.hxml` builds
- [ ] 2.2 Every `TEXTURE_MAX_ANISOTROPY_EXT` and `DEPTH_CLAMP` call in `GlDriver.hx` is behind its flag, and `hasExtension` is called only from the constructor
