## 1. Implementation

- [x] 1.1 `hxd.snd.effect.Pan`: `value`, `Pan.mix` (the `StereoPannerNode` law over PCM, ramped)
- [x] 1.2 WebAudio: `StereoPannerNode` in `SourceHandle.updateDestination`, `PanDriver`, registered as `"pan"`
- [x] 1.3 `hxd.snd.Manager`: a panned channel on another driver streams mixed stereo buffers (`PAN_BUFFER_SAMPLE_COUNT`, `PAN_BUFFER_QUEUE_LENGTH`), rebinds when a `Pan` is added or removed
- [x] 1.4 OpenAL: `PanDriver` sets `AL_DIRECT_CHANNELS_SOFT`, registered as `"pan"` under `hlopenal`

## 2. Verification

- [x] 2.1 `tests/PanTest.hx`: `Pan.mix` against the `StereoPannerNode` law, mono and stereo (including a sum above full scale, float out), over `[-1, 1]`; through the Manager with a recording driver: mixed stereo buffers, queue filled, ramp on a change, `value = 0` leaves a stereo clip unchanged, removal back to the plain buffer at the reached sample, mono mixed to stereo; the emulator and the virtual mode play a panned channel without failing
- [x] 2.2 `haxe all.hxml` builds
