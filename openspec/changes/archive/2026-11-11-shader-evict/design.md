# Design

## Context

`hxsl.Cache.link` walks `linkCache`, a tree of `SearchMap` nodes keyed by `ShaderInstance.id`, one level per shader of the list; the leaf holds the linked `RuntimeShader`. `byID` maps a runtime shader's code signature to the first shader that had it, and later shaders with the same signature take its `id`, so drivers (which key compiled programs by `RuntimeShader.id`) share one program between them. `batchShaders` / `batchShadersParams` map a source `RuntimeShader` to the batch `SharedShader` made from it. `OutputShader` keeps the cache it was created with, so a fresh `hxsl.Cache` is not seen by existing passes; eviction from the live cache avoids that problem altogether.

## Decisions

- **Evict by instance id, from the live cache.** The ids are those of `shader`'s `instanceCache`. Every child of a `SearchMap` whose id is one of them is cut off with its whole subtree; the `linked` shaders of that subtree are the removed ones. Nodes left with neither a shader nor children are pruned too. The walk collects the surviving runtime shaders on the way, so one pass answers both questions.
- **Batch shaders follow their source.** A removed runtime shader that is a key of a batch map is removed from it, and the batch `SharedShader` is evicted in turn (its instances are linked through the same tree).
- **Signature table stays consistent.** When `byID` points at a removed shader, it is re-pointed at a surviving shader of the same signature (which carries the same id), or deleted when there is none — so a later compile of the same text either reuses the live program or allocates a fresh id.
- **Programs are released per id, not per shader.** `disposeShader` is called once for each id carried by a removed shader and by no surviving one. A runtime shader still held somewhere else (a pass that has not relinked yet) stays usable: `GlDriver` recompiles a missing program from the code `releaseData` keeps, as after a context loss.
- **Driver choice.** `evict(shader, ?driver)`: an explicit driver for tests and tools, the current engine's otherwise. `Driver.disposeShader` is a no-op by default; only GL frees anything now, which is where the leak was measured.

## Risks / Trade-offs

- The walk is linear in the size of the cache; eviction happens on an edit, not per frame.
- `SearchMap.get` stays on the hot path; removal is written so that `get` gains no extra branch.
