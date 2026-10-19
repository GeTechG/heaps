## ADDED Requirements

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
