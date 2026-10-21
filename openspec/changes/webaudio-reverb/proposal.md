## Why
`hxd.snd.effect.Reverb` is an EFX reverb on OpenAL (HashLink), but the WebAudio driver never got its reverb driver (`// case "reverb" : new ReverbDriver(this);` in `hxd/snd/webaudio/Driver.hx`), so on the web the effect silently falls back to the no-op `EffectDriver` (HPS-34). Sprout shares one `Reverb` between the voices of an audio bus and needs to hear its tail in the web build (SPR-257).

On the way: `webaudio/LowPassDriver.bind` with a second `LowPass` on the same source replaces `source.lowPass` without releasing the first node; when either `LowPass` is then removed, the source is left with no filter node and the remaining one fails on its next `apply`.

## What Changes
- `hxd.snd.webaudio.ReverbDriver`: one `ConvolverNode` per `Reverb` instance, fed by every source the effect is bound to (a send from the source gain, in parallel with the dry path), its output scaled by `wetDryMix / 100` (as `EFFECTSLOT_GAIN` on OpenAL) into the driver's destination. The impulse response is generated from the I3DL2 fields of the effect and regenerated when one of them changes; `wetDryMix` changes only the gain. `retainTime` is the duration of the response, so the tail is not cut when the last channel leaves.
- `webaudio/Driver.getEffectDriver("reverb")` returns it.
- `webaudio/Driver.getEffectsOutput()`: one gain on the destination that every reverb output goes through; `Manager.paused` mutes it (`Driver.setEffectsPaused`, called from `Manager.pauseDevice`), since WebAudio has no device pause and a tail goes on after the sources are released.
- `webaudio/LowPassDriver`: a source keeps one filter node however many `LowPass` effects are bound to it; it is released when the last one is removed. The last applied `gainHF` wins, as on OpenAL where a source has one direct filter.

## Capabilities

### New Capabilities
- `sound-reverb`: the `Reverb` effect on the WebAudio driver.
- `sound-lowpass`: several `LowPass` effects on one channel.

### Modified Capabilities

## Impact
`hxd/snd/webaudio/` (new `ReverbDriver.hx`, `Driver.hx`, `LowPassDriver.hx`, `AudioTypes.hx`), `hxd/snd/Manager.hx` (`pauseDevice` on WebAudio), the test `tests/WebAudioReverbTest.hx`. OpenAL, the emulator and the virtual mode are unchanged.
