## 1. Implementation

- [ ] 1.1 `hxd.snd.webaudio.ReverbDriver`: impulse response from the I3DL2 fields, convolver send shared by the bound sources, wet gain from `wetDryMix`, regenerated on change, `retainTime`
- [ ] 1.2 `webaudio/Driver.getEffectDriver("reverb")`
- [ ] 1.3 effects output gain of the WebAudio driver, muted by `Manager.paused`
- [ ] 1.4 `webaudio/LowPassDriver`: one filter node per source, counted, released with the last `LowPass`

## 2. Verification

- [ ] 2.1 `tests/WebAudioReverbTest.hx` (node, a recording stub of the WebAudio graph): two channels share one `Reverb`, the tail decays by 60 dB over `decayTime` and starts after the delays, a changed parameter regenerates the response, `wetDryMix` sets the wet gain, unbinding cuts only the send, a pause mutes playing and retained tails; two `LowPass` on one channel, either removed, leave a working filter
- [ ] 2.2 `haxe all.hxml` builds
