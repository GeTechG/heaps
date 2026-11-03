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
The convolver's impulse response SHALL be stereo, not normalized by the node, and made of early reflections starting `reflectionsDelay` after the input, at gain `reflections · room`, and a late tail starting `reverbDelay` after them, at gain `reverb · room`, whose energy decays by 60 dB over `decayTime` below `hfReference` and over `decayTime · decayHFRatio` above it, the part above `hfReference` scaled by `roomHF`. Millibels SHALL be converted to amplitude as `10^(mB / 2000)`.

#### Scenario: Tail decay
- **WHEN** the impulse response of a `Reverb` is generated
- **THEN** it is silent before `reflectionsDelay`, its late tail starts after `reflectionsDelay + reverbDelay`, and the energy below `hfReference` falls by 60 dB over `decayTime`

#### Scenario: High frequencies
- **WHEN** `decayHFRatio` is 0.5
- **THEN** the energy of the tail above `hfReference` falls by 60 dB over half of `decayTime`

### Requirement: the energy and density of the impulse response
The energy of each part of the impulse response SHALL equal the square of its gain (the tail's before `roomHF`), so a noise-like input comes out of each part at that gain. `density` SHALL set how many early reflections there are and `diffusion` how dense the tail is. `roomRolloffFactor` SHALL NOT affect the response.

#### Scenario: Energy of the parts
- **WHEN** the impulse response of a `Reverb` is generated
- **THEN** the energy of its early reflections is the square of `reflections · room` and that of its tail, before `roomHF`, the square of `reverb · room`, both as amplitudes

#### Scenario: Density
- **WHEN** two responses differ only by `density`, one at its minimum and one at its maximum
- **THEN** the one at the maximum has more early reflections

### Requirement: the impulse response is regenerated when its fields change
The impulse response SHALL be regenerated when one of the fields it is generated from changes, and SHALL NOT be when only `wetDryMix` changes.

#### Scenario: Parameter changed at runtime
- **WHEN** `decayTime` of a bound `Reverb` changes and the Manager updates
- **THEN** the convolver gets a response generated from the new value

#### Scenario: Only the mix changes
- **WHEN** only `wetDryMix` of a bound `Reverb` changes and the Manager updates
- **THEN** the convolver keeps its response

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

### Requirement: the first channel on a new Reverb is reverberated from its start
On WebAudio the buffers of a source SHALL NOT start playing before the effects bound to its channel in the same `Manager.update` are set up: `Driver.playSource` SHALL only mark the source started, and `Driver.update()` at the end of that `Manager.update` SHALL start its buffers, chained in queue order.

#### Scenario: Short channel on a new Reverb
- **WHEN** a 30 ms channel with a newly created `Reverb` is played and the Manager updates
- **THEN** its buffer source nodes are started only once their output reaches the effect's convolver, which already has its response

#### Scenario: Slow response
- **WHEN** a channel is played on a newly acquired `Reverb` whose impulse response takes longer to generate than the channel lasts
- **THEN** the convolver, with its response, is connected to the channel's send before the channel's first sample is played

#### Scenario: Several queued buffers
- **WHEN** a source has several buffers queued when `Driver.update()` starts it
- **THEN** they are started one after the other, in queue order

### Requirement: impulse responses are reused
Generated impulse responses SHALL be kept by the WebAudio reverb driver in a bounded cache keyed by the fields the response depends on and the sample rate. A `Reverb` whose fields match a cached response, a new one or one acquired again after its retention ended, SHALL use that response without generating it again.

#### Scenario: Second Reverb with the same preset
- **WHEN** a second `Reverb` with the same fields as one already used is played on a channel and the Manager updates
- **THEN** its convolver gets the same response buffer as the first one
