## Why
A 2D game places a sound left or right of the listener by panning its channel (HPS-25). Heaps has no stereo pan: `hxd.snd.effect.Spatialization` is 3D, and OpenAL does not position stereo buffers, which most clips are.

OpenAL cannot give the levels of WebAudio's `StereoPannerNode` through `AL_EXT_STEREO_ANGLES`: measured on OpenAL Soft 1.23.1 (stereo output), its panning law is not equal-power, and one source gain cannot correct one channel of a stereo clip without the other. The maintainer chose exact parity by mixing in software on that path (HPS-25, option B).

## What Changes
- New effect `hxd.snd.effect.Pan`: `value` in `[-1, 1]`, changeable while the channel plays, and `Pan.mix`, the `StereoPannerNode` law over PCM.
- WebAudio: a `StereoPannerNode` in the source's node chain.
- Every other driver (OpenAL, its emulator, `usesys`): `hxd.snd.Manager` streams a panned channel as short stereo buffers mixed by `Pan.mix`, ramping from the previous value over each buffer, in float where the driver takes it; adding or removing a `Pan` rebinds the source at its position. With hlopenal the source plays them with `AL_SOFT_direct_channels`, so OpenAL adds no panning of its own.

## Impact
- New capability `sound-pan`.
- Code: `hxd/snd/effect/Pan.hx`, `hxd/snd/Manager.hx`, `hxd/snd/webaudio/{PanDriver,Driver,AudioTypes}.hx`, `hxd/snd/openal/{PanDriver,Driver}.hx`, `tests/PanTest.hx`.
- A panned channel on these drivers costs a decode and a mix per buffer and hears a change of `value` after the buffers already queued (`Manager.PAN_BUFFER_SAMPLE_COUNT` × `Manager.PAN_BUFFER_QUEUE_LENGTH`, ~140 ms at 44.1 kHz by default).
