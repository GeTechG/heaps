## 1. Cache eviction

- [x] 1.1 `tests/ShaderEvictTest.hx`: interp test with `hxsl.Cache` and a recording driver covering the scenarios of `shader-cache` "evicting a SharedShader forgets its linked shaders" and "evicting releases compiled programs no one shares"; fails before 1.2
- [x] 1.2 `hxsl/Cache.hx`: `SearchMap.remove`, `Cache.evict(shader, ?driver)` pruning `linkCache`, the batch maps and `byID`; `getLinkShader` initializes `priority` and `constBits`, which `createEmptyInstance` leaves null on eval — checked by 1.1 passing
- [x] 1.3 `h3d/impl/Driver.hx`, `h3d/impl/RenderGraphDriver.hx`: `disposeShader`, no-op by default and forwarded — checked by 1.1 (the recording driver overrides it) and `haxe all.hxml`

## 2. GL programs

- [x] 2.1 `h3d/impl/GlDriver.hx`: `disposeShader` deletes and forgets the program, and the current program if it is that one (JS `deleteProgram`; HL/SDL binds `sdl.hdll`'s `gl_delete_program`, which `sdl.GL` does not expose) — checked by `haxe all.hxml` and 2.3
- [x] 2.2 `tests/ShaderEvictTest.hx` with `-D evict_gl`: an HL/SDL app that draws with a dynamic shader, evicts it, checks `GlDriver.programs` dropped its ids, draws with a new text and reselects an evicted runtime shader, with no GL error — checked by compiling it (`-lib hlsdl -D evict_gl -hl`)
- [ ] 2.3 [human] On a machine with HashLink and `sdl.hdll` (hashlink 3b7bd74 or later) and a display, run the first line of `tests/ShaderEvictTest.hx`; both halves print `OK` (`ShaderEvictTest: OK`, then `ShaderEvictTest (GL): OK`) and the window closes by itself
- [x] 2.4 AGENTS.md *Checks*

## Workflow follow-up

- Sprout (SPR-711) calls `hxsl.Cache.get().evict(old)` when it replaces a live-edited shader, after bumping its heaps gitlink.
