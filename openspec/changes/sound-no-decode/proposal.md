## Why
A JS game can decode its sounds with the browser (`decodeAudioData`) and hand `hxd.res.Sound` a ready `hxd.snd.Data` before the first `play()`. The Haxe decoders then never run, but they stay in the output even under `-dce full`: `hxd.res.Sound.getData()`, which `hxd.snd.Manager.play` calls, refers to `hxd.snd.WavData` and `hxd.snd.Mp3Data`, and through them to `format.wav` and `format.mp3`. `hxd.snd.Data.resample` keeps `WavData` as well, as a container for the resampled PCM (HPS-24).

## What Changes
- `-D heaps_no_sound_decode`: `hxd.res.Sound.getData()` without data set beforehand throws `"Sound has no data <path>"` instead of decoding the resource bytes. Without the define nothing changes.
- `hxd.res.Sound.setData(data)`: the public way to set the data to play.
- `hxd.snd.Data.resample` returns its PCM in a private raw-PCM `Data` instead of a `WavData`.

## Capabilities

### New Capabilities
- `sound-resource`: how `hxd.res.Sound` gets the data it plays, and building without the sound decoders.

### Modified Capabilities

## Impact
`hxd/res/Sound.hx`, `hxd/snd/Data.hx`, the test `tests/SoundNoDecodeTest.hx`. Without the define the only visible difference is the class of the data `resample` returns.
