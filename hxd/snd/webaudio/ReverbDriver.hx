package hxd.snd.webaudio;

#if (js && !useal)
import js.html.audio.AudioBuffer;
import js.html.audio.ConvolverNode;
import js.html.audio.GainNode;
import js.lib.Float32Array;
import hxd.snd.effect.Reverb;
import hxd.snd.Driver.EffectDriver;
import hxd.snd.webaudio.AudioTypes;

/**
	I3DL2 reverb on WebAudio: every source the effect is bound to sends its gain output to one ConvolverNode,
	whose impulse response is generated from the effect parameters, in parallel with the dry path.
**/
class ReverbDriver extends EffectDriver<Reverb> {

	static inline var EARLY_MAX_TAPS = 8;
	static inline var CACHE_SIZE = 8;

	// generated responses by their parameters, most recently used last
	static var cache : Array<{ key : String, buffer : AudioBuffer }> = [];

	var driver    : Driver;
	var input     : GainNode;
	var convolver : ConvolverNode;
	var wet       : GainNode;
	var params    : Array<Float>;

	public function new(driver) {
		super();
		this.driver = driver;
	}

	override function acquire() : Void {
		input = driver.ctx.createGain();
		wet = driver.ctx.createGain();
		wet.connect(driver.getEffectsOutput());
		params = null;
	}

	override function release() : Void {
		input.disconnect();
		if ( convolver != null ) convolver.disconnect();
		wet.disconnect();
		input = null;
		convolver = null;
		wet = null;
	}

	override function update(e : Reverb) : Void {
		var p = [e.room, e.roomHF, e.decayTime, e.decayHFRatio, e.reflections, e.reflectionsDelay,
			e.reverb, e.reverbDelay, e.diffusion, e.density, e.hfReference, driver.ctx.sampleRate];
		var changed = params == null;
		if ( !changed ) for ( i in 0...p.length ) if ( p[i] != params[i] ) { changed = true; break; }
		if ( changed ) {
			params = p;
			var c = driver.ctx.createConvolver();
			c.normalize = false;
			c.buffer = getResponse(e, p.join(","));
			c.connect(wet);
			input.connect(c);
			if ( convolver != null ) {
				input.disconnect(convolver);
				convolver.disconnect();
			}
			convolver = c;
		}
		wet.gain.value = e.wetDryMix / 100.0;
		driver.getEffectsOutput(); // follows a change of the driver destination

		// keep the convolver until its whole response has played out
		@:privateAccess
		e.retainTime = convolver.buffer.duration;
	}

	override function bind(e : Reverb, source : SourceHandle) : Void {
		source.gain.connect(input);
	}

	override function unbind(e : Reverb, source : SourceHandle) : Void {
		if ( source.gain != null ) try source.gain.disconnect(input) catch( _ : Dynamic ) {}
	}

	function getResponse( e : Reverb, key : String ) : AudioBuffer {
		for ( i in 0...cache.length ) if ( cache[i].key == key ) {
			var r = cache.splice(i, 1)[0];
			cache.push(r);
			return r.buffer;
		}
		var rate = driver.ctx.sampleRate;
		var channels = generate(e, rate);
		var buf = driver.ctx.createBuffer(channels.length, channels[0].length, rate);
		for ( i in 0...channels.length ) buf.getChannelData(i).set(channels[i]);
		cache.push({ key : key, buffer : buf });
		if ( cache.length > CACHE_SIZE ) cache.shift();
		return buf;
	}

	static inline function mbToGain( mb : Float ) : Float {
		return Math.pow(10, mb / 2000);
	}

	/**
		Stereo impulse response of the reverb `e` at `rate` Hz: early reflections `reflectionsDelay` after the input,
		then the late tail `reverbDelay` after them, decaying by 60 dB over `decayTime` below `hfReference`
		and over `decayTime * decayHFRatio` above it. The energy of each part is the square of its gain.
	**/
	public static function generate( e : Reverb, rate : Float ) : Array<Float32Array> {
		var room = mbToGain(e.room);
		var earlyGain = mbToGain(e.reflections) * room;
		var lateGain = mbToGain(e.reverb) * room;
		var roomHF = mbToGain(e.roomHF);
		var decay = hxd.Math.max(e.decayTime, 0.1);
		var decayHF = decay * hxd.Math.clamp(e.decayHFRatio, 0.1, 2.0);
		var diffusion = hxd.Math.clamp(e.diffusion / 100, 0, 1);
		var density = hxd.Math.clamp(e.density / 100, 0, 1);
		var earlyStart = Math.round(hxd.Math.max(e.reflectionsDelay, 0) * rate);
		var lateStart = earlyStart + Math.round(hxd.Math.max(e.reverbDelay, 0) * rate);
		var lateLength = Math.ceil(hxd.Math.max(decay, decayHF) * rate);
		var length = lateStart + lateLength;

		// early reflections: taps spread over the reverb delay
		var taps = 1 + Math.round(density * (EARLY_MAX_TAPS - 1));
		var window = hxd.Math.max(lateStart - earlyStart, Math.round(0.005 * rate));
		// late tail: noise with one sample in `keep` when not fully diffuse, split in two bands at hfReference
		var keep = 0.1 + 0.9 * diffusion;
		var cut = 1 - Math.exp(-2 * Math.PI * hxd.Math.clamp(e.hfReference, 20, rate * 0.45) / rate);
		var stepLow = Math.exp(-3 * Math.log(10) / (decay * rate));
		var stepHigh = Math.exp(-3 * Math.log(10) / (decayHF * rate));

		var rnd = new hxd.Rand(0x5EED);
		var out = [];
		for ( ch in 0...2 ) {
			var data = new Float32Array(length);
			for ( t in 0...taps ) {
				var pos = earlyStart + (t == 0 ? 0 : Std.int(window * (t + rnd.rand()) / taps));
				if ( pos >= length ) pos = length - 1;
				data[pos] += (t == 0 || rnd.rand() < 0.5 ? 1 : -1) * earlyGain / Math.sqrt(taps);
			}

			var low = new Float32Array(lateLength), high = new Float32Array(lateLength);
			var lp = 0., energy = 0., envLow = 1., envHigh = 1.;
			for ( i in 0...lateLength ) {
				var x = rnd.rand() < keep ? rnd.srand() / Math.sqrt(keep) : 0.;
				lp += cut * (x - lp);
				var l = lp * envLow, h = (x - lp) * envHigh;
				envLow *= stepLow;
				envHigh *= stepHigh;
				low[i] = l;
				high[i] = h;
				energy += (l + h) * (l + h);
			}
			var scale = energy > 0 ? lateGain / Math.sqrt(energy) : 0;
			for ( i in 0...lateLength )
				data[lateStart + i] += (low[i] + high[i] * roomHF) * scale;
			out.push(data);
		}
		return out;
	}
}
#end
