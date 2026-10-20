## Why
A game wants to ship its sounds as Ogg Opus. Heaps decodes Ogg Vorbis (`hxd.snd.OggData`), MP3 and WAV, but not Opus. On HashLink `fmt.hdll` now has Opus primitives (`opus_open`, `opus_info`, `opus_seek`, `opus_read`; hashlink HL-62); on JS the browser decodes Opus and the game hands the result to `hxd.res.Sound.setData`.

## What Changes
- `hxd.snd.OpusData` (HashLink): Ogg Opus data decoded by `fmt.hdll`. 48 kHz, the stream's channel count, `samples` per channel after the pre-skip, decoded on demand by chunks as `I16` or `F32`. On other targets the class exists but throws on construction.
- `hxd.res.Sound.getData()` on HashLink: an Ogg stream whose first packet is `OpusHead` is decoded by `OpusData`; any other Ogg stream goes to `OggData` as before.
- `hxd.res.SoundFormat.OggOpus`; `Sound.supportedFormat(OggOpus)` is `true` on HashLink only.
- Other targets: no change; nothing refers to `OpusData`, so it is not in their output unless a program uses it.

## Capabilities

### New Capabilities

### Modified Capabilities
- `sound-resource`: Ogg Opus resources on HashLink.

## Impact
`hxd/snd/OpusData.hx` (new), `hxd/res/Sound.hx`, the test `tests/OpusDataTest.hx` with its clips. Needs an `fmt.hdll` built with Opus (hashlink 193d8631 or later); an older one fails the first `OpusData` with "Opus is not supported by this fmt.hdll" or a missing primitive.
