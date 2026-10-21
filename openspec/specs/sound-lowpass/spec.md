# sound-lowpass Specification

## Purpose
Several `hxd.snd.effect.LowPass` effects on one channel.

## Requirements

### Requirement: several LowPass effects on one channel
When several `hxd.snd.effect.LowPass` effects are bound to one channel, the channel SHALL be filtered once, with the `gainHF` of the last one applied, as on OpenAL where a source has one direct filter. Removing one of them SHALL leave the channel filtered by the others; removing the last SHALL remove the filter. On WebAudio the source SHALL keep one `BiquadFilterNode` for all of them.

#### Scenario: Two LowPass, the first removed
- **WHEN** two `LowPass` effects are on a playing channel on WebAudio and the first is removed
- **THEN** the channel keeps its filter node, the second `LowPass` goes on applying to it, and no update fails
