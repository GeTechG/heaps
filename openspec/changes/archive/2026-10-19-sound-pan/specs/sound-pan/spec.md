## ADDED Requirements

### Requirement: a channel is panned by the Pan effect
`hxd.snd.effect.Pan`, added to a channel or its channel group, SHALL pan the channel by `value`: `-1` fully left, `0` centre, `1` fully right; a value outside `[-1, 1]` SHALL be clamped. A change of `value` on a playing channel SHALL take effect without restarting it. On a stereo clip `value = 0` SHALL leave both channels at their level.

#### Scenario: Pan changed while playing
- **WHEN** `value` of a `Pan` on a playing channel is changed
- **THEN** the channel goes on playing with the new pan

### Requirement: the same equal-power law on every driver
The levels SHALL follow the equal-power law of WebAudio `StereoPannerNode`. A mono clip gets `L = in · cos((value + 1) · π/4)`, `R = in · sin((value + 1) · π/4)`; a stereo clip with `value <= 0` gets `L = inL + inR · cos((value + 1) · π/2)`, `R = inR · sin((value + 1) · π/2)`, and with `value > 0` `L = inL · cos(value · π/2)`, `R = inR + inL · sin(value · π/2)`. WebAudio SHALL use a `StereoPannerNode`. Every other driver SHALL receive the panned channel as stereo buffers of `Manager.PAN_BUFFER_SAMPLE_COUNT` frames mixed by `Pan.mix` with this law, `Manager.PAN_BUFFER_QUEUE_LENGTH` of them queued; a buffer SHALL ramp the pan linearly from the value its predecessor ended with to the current one. With hlopenal the source SHALL play them with `AL_SOFT_direct_channels`, so OpenAL adds no panning of its own. The mixed buffers SHALL be 32-bit float where the driver takes float (hlopenal, the emulator under JS), so a stereo clip panned to a side keeps the sum of its channels (up to twice full scale) until the source gain applies; elsewhere they are in the sound's target format and clip at full scale.

#### Scenario: Mixed levels match StereoPannerNode
- **WHEN** a mono or stereo frame is mixed by `Pan.mix` for a value in `[-1, 1]`
- **THEN** the left and right levels equal those of the `StereoPannerNode` law

#### Scenario: A change ramps over the next buffer
- **WHEN** `value` goes from `a` to `b` on a channel mixed by the Manager
- **THEN** the next buffer starts at `a` and ends at `b`

### Requirement: adding or removing a Pan on a playing channel
When a `Pan` is added to or removed from a playing channel on a driver other than WebAudio, the Manager SHALL rebind the channel's source at its current position, from its plain buffers to mixed ones or back.

#### Scenario: Pan removed
- **WHEN** the `Pan` of a channel mixed by the Manager is removed after it has played some samples
- **THEN** the channel plays its plain sound buffer again from the sample it had reached

### Requirement: no driver fails on the effect
A `Pan` SHALL NOT fail in the virtual mode of `hxd.snd.Manager` (no driver) or with the OpenAL emulator.

#### Scenario: Emulator and virtual mode
- **WHEN** a channel with a `Pan` plays and the Manager updates, with the OpenAL emulator or with no driver
- **THEN** nothing fails
