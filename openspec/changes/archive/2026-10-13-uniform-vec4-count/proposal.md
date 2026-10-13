## Why
On a native target `h3d.impl.GlDriver.uploadBuffer` uploads the `Globals` and `Params` uniform arrays with `gl.uniform4fv(loc, bytes, 0, size * 4)`. The last argument of the HashLink bindings is the `count` of `glUniform4fv(loc, count, ptr)` — a number of `vec4`, not of floats — and `globalsSize` / `paramsSize` already are numbers of `vec4`. The driver therefore asks for four times more elements than the `uniform vec4 …[size]` array holds, and lets GL read past the `size * 16` bytes it copied. Desktop OpenGL ignores the excess; ANGLE (OpenGL ES 3.1, Android emulator) answers `GL_INVALID_OPERATION` on every frame that uploads such a buffer (HPS-22, found in SPR-165).

## What Changes
- `GlDriver.uploadBuffer`, `#if hl` path, `Globals` and `Params` branches: the count passed to `uniform4fv` is `globalsSize` / `paramsSize`.
- The JS path (a typed-array view of `size * 4` floats) is untouched.

## Capabilities

### New Capabilities

### Modified Capabilities
- `gl-driver-gles`: a new requirement — a uniform array upload names exactly the number of elements the array has.

## Impact
`h3d/impl/GlDriver.hx` only. The elements written to the array are the same as before, so rendering does not change; the per-frame `GL_INVALID_OPERATION` on OpenGL ES is gone, and GL no longer reads past the uploaded data.
