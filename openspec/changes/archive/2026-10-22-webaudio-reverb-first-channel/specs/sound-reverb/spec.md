## ADDED Requirements

### Requirement: the first channel on a new Reverb is reverberated from its start
On WebAudio the buffers of a source SHALL NOT start playing before the effects bound to its channel in the same `Manager.update` are set up: `Driver.playSource` SHALL only mark the source started, and its buffers SHALL be started by `Driver.update()` at the end of that `Manager.update`, chained in queue order. A `Reverb` acquired for a channel SHALL therefore have its convolver, with its impulse response, connected to the channel's send before the channel's first sample is played, however short the channel and however long the response takes to generate.

#### Scenario: Short channel on a new Reverb
- **WHEN** a 30 ms channel with a newly created `Reverb` is played and the Manager updates
- **THEN** its buffer source nodes are started only once their output reaches the effect's convolver, which already has its response

### Requirement: impulse responses are reused
Generated impulse responses SHALL be kept by the WebAudio reverb driver in a bounded cache keyed by the fields the response depends on and the sample rate. A `Reverb` whose fields match a cached response, a new one or one acquired again after its retention ended, SHALL use that response without generating it again.

#### Scenario: Second Reverb with the same preset
- **WHEN** a second `Reverb` with the same fields as one already used is played on a channel and the Manager updates
- **THEN** its convolver gets the same response buffer as the first one
