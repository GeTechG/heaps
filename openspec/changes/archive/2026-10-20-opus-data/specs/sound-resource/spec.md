## ADDED Requirements

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
