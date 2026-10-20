## 1. Implementation

- [ ] 1.1 `hxd.snd.OpusData` on HashLink over the `fmt` Opus primitives: info, `I16`/`F32` decoding by chunks with seek; a throwing stub on other targets
- [ ] 1.2 `hxd.res.Sound.getData`: `OggS` + `OpusHead` first packet → `OpusData` on HashLink, other Ogg → `OggData`
- [ ] 1.3 `SoundFormat.OggOpus` and `supportedFormat`

## 2. Verification

- [ ] 2.1 `tests/OpusDataTest.hx` (HL): mono and stereo clips give 12000 samples, their channels, 48 kHz; decoding by chunks equals decoding the whole clip; the PCM matches the `opusdec` reference; `hxd.res.Sound` picks `OpusData` for Opus and not for another Ogg stream
- [ ] 2.2 a `-dce full` JS build that plays a `hxd.res.Sound` has no `hxd_snd_OpusData`
- [ ] 2.3 `haxe all.hxml` builds
