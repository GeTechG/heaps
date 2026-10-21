# sound-manager Specification

## Purpose
What `hxd.snd.Manager` does when no audio device can be opened, and how it pauses the mix.

## Requirements

### Requirement: no audio device, virtual mode
When creating the sound driver or allocating its sources throws, whatever the thrown value, `hxd.snd.Manager.get()` SHALL return a Manager without a driver instead of propagating it: a driver that was created SHALL be disposed, every channel SHALL be virtual, and channels SHALL advance and end as they do with a driver. `Manager.driverError` SHALL hold the exception, `null` when the driver was created.

#### Scenario: Driver throws a haxe.Exception
- **WHEN** the driver constructor throws a `haxe.Exception` and `Manager.get()` is called
- **THEN** the Manager is created without a driver, `driverError` holds that exception, and a played channel is virtual and ends after its duration

#### Scenario: Device opens
- **WHEN** the driver is created
- **THEN** `driverError` is `null`

### Requirement: pause at the device
`hxd.snd.Manager.paused` SHALL pause the whole mix while `true`: the OpenAL driver SHALL pause the device with `ALC_SOFT_pause_device`; with any other driver, or where the extension is missing, every channel SHALL give up its source, keeping its position, and get one again on resume; `Manager.update` SHALL queue no buffer and advance no virtual channel and no fade. When `paused` is set back to `false`, every channel, channel fade and channel group fade SHALL go on from the position it had when the pause began: the time spent paused SHALL NOT count for them. Without a driver only the timing applies. A channel played while paused SHALL start when the Manager resumes. A source released from a channel SHALL give the channel back, in order, the queued sounds it had buffered but not reached.

#### Scenario: Pause and resume
- **WHEN** a channel at position 1 s is paused with `Manager.paused = true`, 10 s pass, and `paused` is set to `false`
- **THEN** no buffer is queued during those 10 s, and the channel goes on from 1 s

#### Scenario: Queued sound behind a released source
- **WHEN** a sound queued on a channel is already buffered on its source and the source is released (pause without a device pause, virtualization, a position change)
- **THEN** the sound goes back to the channel's queue and plays once, after the current one

#### Scenario: Virtual channel
- **WHEN** a virtual channel is paused the same way
- **THEN** its `position` does not advance during the pause

### Requirement: paused in the background on HashLink
On HashLink the Manager SHALL set `paused` to `true` when the application goes to the background (`hxd.System` background listener) if it was not already paused, and set it back to `false` on return only if it was the one that paused it. A Manager created while the application is in the background SHALL start paused the same way.

#### Scenario: Background
- **WHEN** the application goes to the background and comes back
- **THEN** the Manager is paused in between and resumed after

#### Scenario: Created in the background
- **WHEN** the first sound is played by a timer while the application is in the background
- **THEN** the Manager is paused until the return

#### Scenario: Paused by the game
- **WHEN** the game set `paused = true` before the application went to the background
- **THEN** the Manager is still paused after the return
