# app-lifecycle Specification

## Purpose
How a HashLink/SDL application learns that it went to the background and came back, and what the main loop does meanwhile.

## Requirements

### Requirement: background and foreground on HashLink/SDL
On HashLink with the SDL library, `hxd.System.isInBackground` SHALL be `true` from SDL's `AppWillEnterBackground` or `AppDidEnterBackground`, whichever comes first, until SDL's `AppDidEnterForeground`, and `false` otherwise. On each change `hxd.System` SHALL call every listener added with `addBackgroundListener` and not removed with `removeBackgroundListener`, in the order they were added, with the new value. A repeated background or foreground event SHALL NOT call them again. Losing focus or minimizing a window SHALL NOT change `isInBackground`. The events SHALL be matched by their numeric values (602, 603, 605), so the sources build with an SDL library that does not define them.

#### Scenario: HOME on Android
- **WHEN** the user presses HOME
- **THEN** `isInBackground` becomes `true` and each listener is called once with `true`

#### Scenario: Return
- **WHEN** the application comes back to the foreground
- **THEN** `isInBackground` becomes `false` and each listener is called once with `false`

#### Scenario: Notification shade
- **WHEN** the window only loses focus
- **THEN** `EFocusLost` is sent and `isInBackground` stays `false`

### Requirement: the main loop in the background
While `isInBackground` is `true` the HashLink main loop SHALL keep handling events and the event loop, SHALL NOT call the loop function nor present a frame, and SHALL sleep between iterations. When the application comes back, `hxd.Timer.skip()` SHALL be called before the loop function runs again.

#### Scenario: Frames in the background
- **WHEN** the application is in the background
- **THEN** the loop function is not called and nothing is presented

#### Scenario: No long frame on return
- **WHEN** the application comes back after a minute in the background
- **THEN** the first frame's `hxd.Timer.elapsedTime` does not include that minute

### Requirement: the game sees the background before SDL holds it
`hxd.System.start` SHALL set SDL's `SDL_ANDROID_BLOCK_ON_PAUSE` hint to `"0"` before `sdl.Sdl.init`, so that on Android the background events reach the game when the application leaves the foreground and not only on return. An environment variable of that name SHALL still take precedence, as SDL gives it.

#### Scenario: Background events on time
- **WHEN** the user presses HOME on Android
- **THEN** the listeners are called with `true` before the user returns to the application
