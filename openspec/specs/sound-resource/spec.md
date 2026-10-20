# sound-resource Specification

## Purpose
How `hxd.res.Sound` gets the data it plays, decoding Ogg Opus on HashLink, and building without the sound decoders.

## Requirements

### Requirement: a sound resource plays data set beforehand
`hxd.res.Sound.setData(data)` SHALL set the data the resource plays; `getData()` SHALL return it without reading the resource bytes.

#### Scenario: Data set before play
- **WHEN** `setData(data)` is called and then `getData()`
- **THEN** `getData()` returns `data`

### Requirement: building without the sound decoders
With `-D heaps_no_sound_decode`, `hxd.res.Sound.getData()` SHALL throw `"Sound has no data <path>"` when no data was set, and SHALL NOT refer to any sound decoder, so that a `-dce full` build that plays sounds keeps none of `hxd.snd.WavData`, `hxd.snd.Mp3Data`, `hxd.snd.OggData`, `format.wav`, `format.mp3`. Without the define, `getData()` decodes the resource bytes by their format, as before.

#### Scenario: JS build with the define
- **WHEN** a `-dce full` JS program built with `-D heaps_no_sound_decode` plays a `hxd.res.Sound` with data set
- **THEN** the output contains no `hxd_snd_WavData`, `hxd_snd_Mp3Data`, `format_mp3` or `format_wav`

#### Scenario: No data set
- **WHEN** `getData()` is called with the define and no data set
- **THEN** it throws `"Sound has no data <path>"`

### Requirement: Ogg Opus data on HashLink
On HashLink, `hxd.snd.OpusData(bytes)` SHALL open an Ogg Opus stream with `fmt.hdll` and throw when the bytes are not one. Its `samplingRate` SHALL be 48000, `channels` the stream's channel count and `samples` the length per channel after the pre-skip. It SHALL decode as `I16`, and as `F32` when resampled to it at the same rate and channel count; `decodeBuffer` SHALL give the same PCM whether a range is decoded at once or by consecutive chunks, and SHALL fill silence past the end of the stream.

#### Scenario: Opening a clip
- **WHEN** `new OpusData(bytes)` is given a stereo Ogg Opus clip of 12000 samples
- **THEN** `samplingRate` is 48000, `channels` is 2 and `samples` is 12000

#### Scenario: Decoding by chunks
- **WHEN** a clip is decoded by consecutive chunks of a few hundred samples
- **THEN** the PCM equals the PCM of the whole clip decoded in one call

### Requirement: a sound resource recognises Ogg Opus
On HashLink, `hxd.res.Sound.getData()` SHALL decode with `hxd.snd.OpusData` an Ogg stream (`OggS`) whose first packet starts with `OpusHead`, and with `hxd.snd.OggData` any other Ogg stream. `Sound.supportedFormat(OggOpus)` SHALL be `true` on HashLink and `false` elsewhere. On other targets `getData()` SHALL behave as before and SHALL NOT refer to `OpusData`, so that a `-dce full` build that does not use it keeps none of it.

#### Scenario: Opus resource on HashLink
- **WHEN** `getData()` is called on a resource holding an Ogg Opus clip on HashLink
- **THEN** it returns an `hxd.snd.OpusData`

#### Scenario: JS build
- **WHEN** a `-dce full` JS program plays a `hxd.res.Sound`
- **THEN** the output contains no `hxd_snd_OpusData`
