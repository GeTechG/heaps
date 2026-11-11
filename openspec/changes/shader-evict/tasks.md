## 1. Cache eviction

- [ ] 1.1 `tests/ShaderEvictTest.hx`: interp test with `hxsl.Cache` and a recording driver covering the scenarios of `shader-cache` "evicting a SharedShader forgets its linked shaders" and "evicting releases compiled programs no one shares"; fails before 1.2
- [ ] 1.2 `hxsl/Cache.hx`: `SearchMap.remove`, `Cache.evict(shader, ?driver)` pruning `linkCache`, the batch maps and `byID` — checked by 1.1 passing
- [ ] 1.3 `h3d/impl/Driver.hx`, `h3d/impl/RenderGraphDriver.hx`: `disposeShader`, no-op by default and forwarded — checked by 1.1 (the recording driver overrides it) and `haxe all.hxml`

## 2. GL programs

- [ ] 2.1 `h3d/impl/GlDriver.hx`: `disposeShader` deletes and forgets the program and the current program if it is that one — checked by `haxe all.hxml` and 2.2
- [ ] 2.2 `tests/ShaderEvictTest.hx` on HashLink/SDL (`-D evict_gl`): draws with a shader, evicts it, checks `GlDriver.programs` dropped its id, draws again with a new text and with the evicted runtime shader without a GL error
- [ ] 2.3 AGENTS.md *Checks*

## Workflow follow-up

- Sprout (SPR-711) calls `hxsl.Cache.get().evict(old)` when it replaces a live-edited shader, after bumping its heaps gitlink.
