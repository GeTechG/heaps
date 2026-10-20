Clips for `OpusDataTest.hx`, taken from hashlink's `other/tests/opus/`: 12000 samples (0.25 s) at 48 kHz.

- `mono.opus`: a 440 Hz sine at half scale.
- `stereo.opus`: a 330 Hz sine on the left, pink noise (amplitude 0.3) on the right.

Encoded with `opusenc --bitrate 48 --max-delay 40`. `<name>.s16` is the reference: `opusdec --no-dither`,
raw signed 16-bit little endian, interleaved. opus-tools 0.2 with libopus 1.5.2 and opusfile 0.12.
