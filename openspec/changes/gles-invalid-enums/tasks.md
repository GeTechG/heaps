## 1. Implementation

- [ ] 1.1 `h3d.impl.GlDriver`, native ES context: do not enable `TEXTURE_CUBE_MAP_SEAMLESS`, do not set `TEXTURE_LOD_BIAS`, report depth clamp as unsupported

## 2. Verification

- [ ] 2.1 `haxe all.hxml` builds
- [ ] 2.2 Every use of the three enums in `GlDriver.hx` is behind the ES check
