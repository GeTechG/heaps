## ADDED Requirements

### Requirement: pause at the device
`hxd.snd.Manager.paused` SHALL pause the whole mix while `true`: the OpenAL driver SHALL pause the device with `ALC_SOFT_pause_device`, or, where the extension is missing, pause every playing source and play them again on resume; `Manager.update` SHALL queue no buffer and advance no virtual channel and no fade. When `paused` is set back to `false`, the time spent paused SHALL be added to `timeOffset`, so that every channel and fade goes on from the position it had when the pause began. Without a driver only the timing applies. A channel played while paused SHALL start when the Manager resumes.

#### Scenario: Pause and resume
- **WHEN** a channel at position 1 s is paused with `Manager.paused = true`, 10 s pass, and `paused` is set to `false`
- **THEN** no buffer is queued during those 10 s, and the channel goes on from 1 s

#### Scenario: Virtual channel
- **WHEN** a virtual channel is paused the same way
- **THEN** its `position` does not advance during the pause

### Requirement: paused in the background on HashLink
On HashLink the Manager SHALL set `paused` to `true` when the application goes to the background (`hxd.System` background listener) if it was not already paused, and set it back to `false` on return only if it was the one that paused it.

#### Scenario: Background
- **WHEN** the application goes to the background and comes back
- **THEN** the Manager is paused in between and resumed after

#### Scenario: Paused by the game
- **WHEN** the game set `paused = true` before the application went to the background
- **THEN** the Manager is still paused after the return
