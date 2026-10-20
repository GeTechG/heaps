## 1. Implementation

- [ ] 1.1 `hxd.System` (HashLink): `isInBackground`, background listeners, the main loop idle in the background, `hxd.Timer.skip()` on return, `SDL_ANDROID_BLOCK_ON_PAUSE` set to `"0"` before `sdl.Sdl.init`
- [ ] 1.2 `hxd.Window` (HashLink/SDL): `AppWillEnterBackground`/`AppDidEnterBackground` → background, `AppDidEnterForeground` → foreground, `RenderDeviceReset` → `GlDriver.onContextReset`, matched by value
- [ ] 1.3 `hxd.snd.openal.Driver.setPaused`: `ALC_SOFT_pause_device`, or pausing and replaying the playing sources
- [ ] 1.4 `hxd.snd.Manager.paused`: device paused, Manager frozen, time away added to `timeOffset` on resume; on HashLink paused while the application is in the background
- [ ] 1.5 `h3d.impl.GlDriver.onContextReset` (HashLink): state reset for the new context, `onCreate(true)`

## 2. Verification

- [ ] 2.1 `tests/LifecycleTest.hx` (eval, fake driver): while paused no buffer is queued and virtual channels and fades do not advance; on resume they go on from the same position; the background listener pauses and resumes a Manager that was not paused, and leaves alone one that was
- [ ] 2.2 `tests/GlContextResetTest.hx` (HashLink/SDL, desktop): `onContextReset` runs `Engine.onContextLost`, textures with `realloc` are reallocated, a frame draws without a GL error
- [ ] 2.3 Android emulator (API 35, x86_64): HOME → `dumpsys audio` shows the game's player not `started`, the listener saw `true`; return → the sound goes on, the listener saw `false`
- [ ] 2.4 `haxe all.hxml` builds
