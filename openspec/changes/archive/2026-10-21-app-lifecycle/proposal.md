## Why
On HashLink/SDL a mobile game cannot follow its own lifecycle. `hxd.Window` turns SDL's window events into `EFocus`/`EFocusLost` only, so going to the background (HOME, the lock screen, a call) looks the same as a pulled-down notification shade or a minimized desktop window. OpenAL-soft keeps mixing while SDL holds the game loop, so the music goes on in the background, and `Manager.suspended` only makes channels virtual: the device plays silence and the virtual positions run ahead by the time spent away. When Android recreates the EGL context on return (SDL `RENDER_DEVICE_RESET`), `GlDriver.isDisposed()` is always `false` on HashLink, so the `onCreate(true)` path never runs and every texture and buffer is dead. The hashlink SDL library now delivers the application events and the reset (hashlink HL-67, `sdl.Event.EventType` 600–605 and 700).

## What Changes
- `hxd.System` (HashLink): `isInBackground`, and `addBackgroundListener`/`removeBackgroundListener` called with `true` when the application goes to the background and `false` when it is back. `hxd.Window` maps SDL's `AppWillEnterBackground`/`AppDidEnterBackground` and `AppDidEnterForeground` to them.
- While in the background the main loop keeps handling events but runs neither the loop function nor `present`, and sleeps between iterations; on return `hxd.Timer.skip()` is called, so the time away is not one frame.
- `System.start` sets SDL's `SDL_ANDROID_BLOCK_ON_PAUSE` hint to `"0"` before `sdl.Sdl.init`: with SDL's default the game loop freezes inside the event pump that carries the background events and the game sees them only on return, too late to stop the sound. An environment variable of that name still overrides it.
- `hxd.snd.Manager.paused`: pauses the mix at the device (`ALC_SOFT_pause_device` through `hxd.snd.openal.Driver.setPaused`; with another driver, or without the extension, every channel gives up its source and gets one again at its position on resume) and freezes the Manager: no buffer is queued, no virtual channel or fade advances. On resume the channels' and fades' stamps are moved past the pause, so every channel goes on from where it stopped. On HashLink the Manager pauses itself while the application is in the background.
- `h3d.impl.GlDriver.onContextReset()` (HashLink): resets the driver's GL state for a new context and runs the engine's `onCreate(true)` path. `hxd.Window` calls it on SDL's `RenderDeviceReset`.
- The new event types are matched by value, so the sources still build with a hashlink SDL library that does not have them; such a library never delivers them.

## Capabilities

### New Capabilities
- `app-lifecycle`: background/foreground on HashLink/SDL and what the main loop does in the background.
- `gl-context-reset`: the GL driver on HashLink recovers from a replaced GL context.

### Modified Capabilities
- `sound-manager`: `Manager.paused`, and the pause in the background.

## Impact
`hxd/System.hl.hx`, `hxd/Window.hl.hx`, `hxd/snd/Manager.hx`, `hxd/snd/openal/Driver.hx`, `h3d/impl/GlDriver.hx`; tests `tests/LifecycleTest.hx` (Manager, eval) and `tests/GlContextResetTest.hx` (HashLink/SDL, needs a display). The events arrive with hashlink at GeTechG/hashlink 28c215a8 or later.
