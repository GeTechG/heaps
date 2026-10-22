## 1. Implementation

- [x] 1.1 `webaudio/Driver`: `playSource` defers the start of the buffers to `Driver.update()`; `queueBuffer` on a source waiting to start only queues; `stopSource` cancels a pending start
- [x] 1.2 `webaudio/ReverbDriver`: response cache keyed by the reverb fields and the sample rate; no per-sample `Math.exp` in `generate`

## 2. Verification

- [x] 2.1 `tests/WebAudioReverbTest.hx`: a 30 ms channel on a new `Reverb` has its source nodes started only once a path from them reaches a convolver with a response; a second `Reverb` with the same fields reuses the response; the existing checks still pass
- [x] 2.2 `haxe all.hxml` builds
