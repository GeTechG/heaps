## Why

A virtual channel (muted, past the source count, too quiet, or without a device) advances its position by wall time, ignoring its `hxd.snd.effect.Pitch`. A real channel plays at its pitch rate (OpenAL `AL_PITCH`, WebAudio `playbackRate`), so a sound at pitch 2 that turns virtual ends twice too late and resumes behind where it should (HPS-49; found in Sprout SPR-590, whose voice limit makes voices virtual by muting them).

## What Changes

- A virtual channel's position advances by the elapsed time times its pitch rate: the value of the channel's own `Pitch` effect, else its channel group's, else 1 — the same pitch a real source of that channel plays at.
- `onEnd`, looping, the next queued sound and the position a channel resumes from on a source follow that clock.
- Channels without a `Pitch` effect keep advancing by wall time.

## Capabilities

### New Capabilities

### Modified Capabilities
- `sound-manager`: adds how a virtual channel's position follows its pitch.

## Impact

`hxd/snd/Manager.hx` (virtual channel update) and a new test `tests/VirtualPitchTest.hx`. No API change.
