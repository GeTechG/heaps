## 1. Implementation

- [x] 1.1 `hxd.System` (HashLink): `isInBackground`, background listeners, the main loop idle in the background, `hxd.Timer.skip()` on return, `SDL_ANDROID_BLOCK_ON_PAUSE` set to `"0"` before `sdl.Sdl.init`
- [x] 1.2 `hxd.Window` (HashLink/SDL): `AppWillEnterBackground`/`AppDidEnterBackground` → background, `AppDidEnterForeground` → foreground, `RenderDeviceReset` → `GlDriver.onContextReset`, matched by value
- [x] 1.3 `hxd.snd.openal.Driver.setPaused`: `ALC_SOFT_pause_device`; elsewhere the Manager releases the sources and binds them again on resume
- [x] 1.4 `hxd.snd.Manager.paused`: device paused, Manager frozen, time away added to `timeOffset` on resume; on HashLink paused while the application is in the background
- [x] 1.5 `h3d.impl.GlDriver.onContextReset` (HashLink): state reset for the new context, `onCreate(true)`

## 2. Verification

- [x] 2.1 `tests/LifecycleTest.hx` (eval, fake driver): while paused no buffer is queued and virtual channels and fades (channel and channel group) do not advance; on resume they go on from the same position; a driver without device pause has its sources released and bound again; the background listener pauses and resumes a Manager that was not paused, and leaves alone one that was
- [x] 2.2 `tests/GlContextResetTest.hx` (HashLink/SDL, desktop): `onContextReset` runs `Engine.onContextLost`, textures with `realloc` are reallocated, a frame draws without a GL error
- [x] 2.3 Android emulator (API 35, x86_64): HOME → `dumpsys audio` shows the game's player not `started`, the listener saw `true`; return → the sound goes on, the listener saw `false`
- [x] 2.4 `haxe all.hxml` builds
