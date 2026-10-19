package hxd.snd.openal;

import hxd.snd.Driver;
import hxd.snd.openal.AudioTypes;
import hxd.snd.effect.Pan;

// The Manager mixes a panned channel into stereo buffers itself (Pan.mix): OpenAL must play them as they are,
// without its own stereo panning, so that the levels are the same as with WebAudio.
class PanDriver extends EffectDriver<Pan> {

	override function bind(e : Pan, s : SourceHandle) : Void {
		AL.sourcei(s.inst, openal.ExtAL.DIRECT_CHANNELS_SOFT, AL.TRUE);
	}

	override function unbind(e : Pan, s : SourceHandle) : Void {
		AL.sourcei(s.inst, openal.ExtAL.DIRECT_CHANNELS_SOFT, AL.FALSE);
	}
}
