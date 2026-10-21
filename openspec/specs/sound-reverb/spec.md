# sound-reverb Specification

## Purpose
The `hxd.snd.effect.Reverb` effect on the WebAudio driver: a convolver per effect fed by its channels, with an impulse response generated from the I3DL2 fields.

## Requirements

### Requirement: Reverb on WebAudio
On the WebAudio driver `hxd.snd.effect.Reverb`, added to a channel or its channel group, SHALL add a reverberated copy of the channel to its dry signal: the channel's source gain SHALL feed a `ConvolverNode` owned by the effect, and the convolver's output, scaled by `wetDryMix / 100`, SHALL go to the driver's destination. The dry path SHALL be unchanged.

#### Scenario: Channel with a Reverb
- **WHEN** a channel with a `Reverb` plays on WebAudio
- **THEN** its source gain is connected both to the destination and to the effect's convolver, and the convolver's output reaches the destination through a gain of `wetDryMix / 100`

### Requirement: the impulse response follows the I3DL2 fields
The convolver's impulse response SHALL be stereo, with no normalization by the node, and generated from the effect: early reflections starting `reflectionsDelay` after the input, at gain `reflections · room` (millibels converted to amplitude, `10^(mB / 2000)`); a late tail starting `reverbDelay` after them, at gain `reverb · room`, its energy decaying by 60 dB over `decayTime` below `hfReference` and over `decayTime · decayHFRatio` above it, the part above `hfReference` scaled by `roomHF`. `density` SHALL set how many early reflections there are and `diffusion` how dense the tail is. The energy of each part SHALL equal the square of its gain (the tail's before `roomHF`), so a noise-like input comes out of each part at that gain. The response SHALL be regenerated when one of these fields changes and SHALL NOT be when only `wetDryMix` changes. `roomRolloffFactor` is not used.

#### Scenario: Tail decay
- **WHEN** the impulse response of a `Reverb` is generated
- **THEN** it is silent before `reflectionsDelay`, its late tail starts after `reflectionsDelay + reverbDelay`, and the energy below `hfReference` falls by 60 dB over `decayTime`

#### Scenario: Parameter changed at runtime
- **WHEN** `decayTime` of a bound `Reverb` changes and the Manager updates
- **THEN** the convolver gets a response generated from the new value

### Requirement: one Reverb on several channels
A `Reverb` added to several channels SHALL feed all of them into its one convolver. Removing it from one channel SHALL disconnect only that channel's send; the tail already in the convolver SHALL go on. The convolver SHALL be kept until `retainTime`, the duration of its impulse response (`reflectionsDelay + reverbDelay + decayTime · max(1, decayHFRatio)`), after the last channel is removed.

#### Scenario: Shared reverb, one channel removed
- **WHEN** one `Reverb` is on two playing channels and one of them stops
- **THEN** the other channel is still connected to the convolver and the convolver still reaches the destination

### Requirement: the tail pauses with the mix
On WebAudio the output of every `Reverb` SHALL go to the destination through one effects gain of the driver (`Driver.getEffectsOutput()`). While `Manager.paused` is `true` that gain SHALL be `0`, so no tail is heard, whether its channels still play or have already stopped while the effect is retained; it SHALL be `1` again when the mix goes on.

#### Scenario: Mix paused with a reverb tail
- **WHEN** `Manager.paused` is set to `true` while channels with a `Reverb` play, then back to `false` and the Manager updates
- **THEN** the effects gain is `0` while paused, and `1` with the channels' sends connected again after the update

#### Scenario: Mix paused during a retained tail
- **WHEN** the last channel of a `Reverb` stopped and the Manager updated, and `Manager.paused` is then set to `true` before `retainTime` has passed
- **THEN** the effects gain is `0`
