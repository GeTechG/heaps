## 1. Implementation

- [x] 1.1 `hxd.res.Sound.getData`: under `heaps_no_sound_decode`, throw when no data was set instead of decoding
- [x] 1.2 `hxd.res.Sound.setData`
- [x] 1.3 `hxd.snd.Data.resample`: a private raw-PCM `Data` instead of `WavData`

## 2. Verification

- [x] 2.1 `tests/SoundNoDecodeTest.hx`: a `-dce full` JS build with the define that plays a `Sound` with data set has no `hxd_snd_WavData`, `hxd_snd_Mp3Data`, `format_mp3`, `format_wav`; without the define it has them
- [x] 2.2 `haxe all.hxml` builds
