## 1. Implementation

- [ ] 1.1 `h3d.impl.GlDriver.uploadBuffer`, `#if hl` path: pass `globalsSize` / `paramsSize` as the `uniform4fv` count in the `Globals` and `Params` branches

## 2. Verification

- [ ] 2.1 `haxe all.hxml` builds
- [ ] 2.2 Every `uniform4fv` call on the `hl` path of `GlDriver.hx` passes a count in `vec4`, matching the bytes handed to `streamData`
