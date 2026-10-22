// Run: haxe -cp . -cp tests -lib format --main WebAudioReverbTest --js test.js && node test.js
// hxd.snd.effect.Reverb on the WebAudio driver: one convolver per effect fed by every channel it is on, a response generated from the I3DL2 fields; several LowPass on one channel share one filter node; a source starts only once its effects are in the graph, so a short first channel on a new Reverb is reverberated.
import hxd.snd.effect.Reverb;
import hxd.snd.effect.LowPass;
import hxd.snd.webaudio.ReverbDriver;

class ConstData extends hxd.snd.Data {
	public function new(samples : Int) {
		this.samples = samples;
		samplingRate = 44100;
		sampleFormat = I16;
		channels = 1;
	}
	override function decodeBuffer(out : haxe.io.Bytes, outPos : Int, sampleStart : Int, sampleCount : Int) {
		for (i in 0...sampleCount) out.setUInt16(outPos + i * 2, 0x1000);
	}
}

class WebAudioReverbTest {

	// a WebAudio graph that only records the connections, enough for hxd.snd.webaudio.Driver under node
	static function stubWebAudio() {
		js.Syntax.code("
			class Param { constructor(v) { this.value = v; } setValueAtTime(v) { this.value = v; } }
			class Node {
				constructor(ctx, kind) { this.context = ctx; this.kind = kind; this.outs = new Set(); ctx.nodes.push(this); }
				connect(n) { this.outs.add(n); return n; }
				disconnect(n) {
					if (n === undefined) { this.outs.clear(); return; }
					if (!this.outs.has(n)) throw new Error('InvalidAccessError');
					this.outs.delete(n);
				}
				addEventListener() {} removeEventListener() {}
				start() {
					// whether what this node plays reaches a convolver that has a response
					const seen = new Set(), reach = n => {
						if (seen.has(n)) return false;
						seen.add(n);
						if (n.kind == 'convolver' && n.buffer != null) return true;
						for (const o of n.outs) if (reach(o)) return true;
						return false;
					};
					globalThis.starts.push({ node: this, wet: reach(this) });
				}
				stop() {}
				setPosition() {} setOrientation() {}
			}
			class Buffer {
				constructor(channels, length, rate) {
					this.numberOfChannels = channels; this.length = length; this.sampleRate = rate; this.duration = length / rate;
					this.data = []; for (let i = 0; i < channels; i++) this.data.push(new Float32Array(length));
				}
				getChannelData(i) { return this.data[i]; }
			}
			globalThis.starts = [];
			globalThis.AudioContext = class {
				constructor() {
					this.nodes = []; this.state = 'running'; this.sampleRate = 48000; this.currentTime = 0;
					this.destination = new Node(this, 'destination');
					this.listener = { setPosition() {}, setOrientation() {} };
				}
				addEventListener() {}
				resume() {}
				createGain() { const n = new Node(this, 'gain'); n.gain = new Param(1); return n; }
				createConvolver() { const n = new Node(this, 'convolver'); n.normalize = true; n.buffer = null; return n; }
				createBiquadFilter() { const n = new Node(this, 'biquad'); n.frequency = new Param(350); n.type = 'lowpass'; return n; }
				createStereoPanner() { const n = new Node(this, 'stereoPanner'); n.pan = new Param(0); return n; }
				createPanner() { return new Node(this, 'panner'); }
				createBufferSource() { const n = new Node(this, 'bufferSource'); n.playbackRate = new Param(1); return n; }
				createBuffer(c, l, r) { return new Buffer(c, l, r); }
			};
		");
	}

	static function check(cond : Bool, what : String) {
		if (!cond) throw what;
	}

	static function connected(a : Dynamic, b : Dynamic) : Bool {
		return a.outs.has(b);
	}

	static function sound(name : String, samples = 44100 * 4) {
		var snd = new hxd.res.Sound(new hxd.fs.BytesFileSystem.BytesFileEntry(name, haxe.io.Bytes.alloc(0)));
		snd.setData(new ConstData(samples));
		return snd;
	}

	static function rms(d : js.lib.Float32Array, from : Int, len : Int) {
		var e = 0.;
		for (i in from...from + len) e += d[i] * d[i];
		return Math.sqrt(e / len);
	}

	static function impulse() {
		var rate = 48000;
		var r = new Reverb();
		r.reflectionsDelay = 0.02;
		r.reverbDelay = 0.03;
		r.decayTime = 1.0;
		r.decayHFRatio = 1.0;
		r.room = 0;
		r.roomHF = 0;
		r.reflections = 0;
		r.reverb = 0;
		var ir = ReverbDriver.generate(r, rate);
		check(ir.length == 2, "stereo response");
		var early = Std.int(0.02 * rate), late = Std.int(0.05 * rate);
		for (d in ir) {
			for (i in 0...early) check(d[i] == 0, "sound before reflectionsDelay at " + i);
			check(d[early] != 0, "no reflection at reflectionsDelay");
			// unit gains: each part has unit energy
			var e = 0.;
			for (i in late...d.length) e += d[i] * d[i];
			check(Math.abs(e - 1) < 0.02, "late energy " + e);
			// 60 dB over decayTime: -30 dB at half of it
			var win = Std.int(0.02 * rate);
			var db = 20 * Math.log(rms(d, late + Std.int(0.5 * rate), win) / rms(d, late, win)) / Math.log(10);
			check(Math.abs(db + 30) < 3, "decay at decayTime/2: " + db + " dB");
		}
		// a shorter HF decay leaves less energy late in the tail
		r.decayHFRatio = 0.2;
		var hf = ReverbDriver.generate(r, rate);
		check(rms(hf[0], late + Std.int(0.5 * rate), 4800) < rms(ir[0], late + Std.int(0.5 * rate), 4800), "decayHFRatio ignored");
		// gains in millibels
		r.decayHFRatio = 1.0;
		r.reverb = -2000;
		var quiet = ReverbDriver.generate(r, rate)[0];
		var e = 0.;
		for (i in late...quiet.length) e += quiet[i] * quiet[i];
		check(Math.abs(Math.sqrt(e) - 0.1) < 0.005, "-2000 mB late gain " + Math.sqrt(e));
	}

	static function graph() {
		var m = hxd.snd.Manager.get();
		var drv : hxd.snd.webaudio.Driver = cast @:privateAccess m.driver;
		check(drv != null && Std.isOfType(drv, hxd.snd.webaudio.Driver), "WebAudio driver expected");
		var ctx : Dynamic = drv.ctx;

		// one Reverb on two channels
		var reverb = new Reverb();
		reverb.wetDryMix = 40;
		check(Std.isOfType(@:privateAccess reverb.driver, ReverbDriver), "reverb driver not used");
		var a = sound("a.wav").play(true);
		var b = sound("b.wav").play(true);
		a.addEffect(reverb);
		b.addEffect(reverb);
		m.update();
		var rd : Dynamic = @:privateAccess reverb.driver;
		var conv : Dynamic = rd.convolver;
		check(conv != null && conv.buffer != null && conv.normalize == false, "convolver with a response");
		check(connected(rd.input, conv) && connected(conv, rd.wet), "send chain");
		var fx : Dynamic = drv.getEffectsOutput();
		check(connected(rd.wet, fx) && connected(fx, drv.destination), "wet not at destination");
		check(Math.abs(rd.wet.gain.value - 0.4) < 1e-9, "wet gain " + rd.wet.gain.value);
		var ga : Dynamic = @:privateAccess a.source.handle.gain, gb : Dynamic = @:privateAccess b.source.handle.gain;
		check(connected(ga, rd.input) && connected(gb, rd.input), "both channels sent");
		check(connected(ga, drv.destination) && connected(gb, drv.destination), "dry path kept");

		// wetDryMix alone keeps the response, another field regenerates it
		reverb.wetDryMix = 100;
		m.update();
		check(rd.convolver == conv && rd.wet.gain.value == 1, "wetDryMix");
		reverb.decayTime = 3;
		m.update();
		check(rd.convolver != conv && connected(rd.input, rd.convolver) && !connected(rd.input, conv), "response not regenerated");
		check(rd.convolver.buffer.length > conv.buffer.length, "longer decay, longer response");
		check(@:privateAccess reverb.retainTime == rd.convolver.buffer.duration, "retainTime");
		// with a slower HF decay the response, and the retention, outlast decayTime
		reverb.decayHFRatio = 1.5;
		m.update();
		check(@:privateAccess reverb.retainTime >= reverb.reflectionsDelay + reverb.reverbDelay + reverb.decayTime * 1.5, "retainTime with decayHFRatio > 1");

		// pausing the mix silences the tail, resuming brings it back
		m.paused = true;
		check(!connected(ga, rd.input) && fx.gain.value == 0, "tail heard while paused");
		m.paused = false;
		m.update();
		check(fx.gain.value == 1, "tail not back after the pause");
		ga = @:privateAccess a.source.handle.gain;
		gb = @:privateAccess b.source.handle.gain;
		check(connected(ga, rd.input) && connected(gb, rd.input), "sends not back after the pause");

		// one channel stops: only its send goes
		a.stop();
		m.update();
		check(!connected(ga, rd.input) && connected(gb, rd.input), "send of the stopped channel");
		check(connected(rd.wet, fx) && connected(fx, drv.destination), "tail cut");
		b.stop();
		m.update();
		// a tail kept after its last channel stopped is paused too
		m.paused = true;
		check(fx.gain.value == 0, "retained tail heard while paused");
		m.paused = false;

		// two LowPass on one channel, the first removed: the second still has its node
		var c = sound("c.wav").play(true);
		var lp1 = new LowPass(), lp2 = new LowPass();
		c.addEffect(lp1);
		m.update();
		c.addEffect(lp2);
		lp2.gainHF = 0.5;
		m.update();
		var h = @:privateAccess c.source.handle;
		var node = h.lowPass;
		check(node != null && h.lowPassRefs == 2, "one filter node");
		c.removeEffect(lp1);
		m.update();
		check(h.lowPass == node && h.lowPassRefs == 1, "filter node lost with the first LowPass");
		lp2.gainHF = 0.25;
		m.update();
		c.removeEffect(lp2);
		m.update();
		check(h.lowPass == null && h.lowPassRefs == 0, "filter node kept after the last LowPass");
		c.stop();
		m.update();
	}

	// a channel shorter than the generation of the response, on a new Reverb: its first sample already goes through the convolver
	static function firstChannel() {
		var m = hxd.snd.Manager.get();
		var starts : Array<Dynamic> = js.Syntax.code("globalThis.starts");
		starts.resize(0);
		var cave = new Reverb();
		cave.decayTime = 3.8;
		var click = sound("click.wav", Std.int(44100 * 0.03)).play();
		click.addEffect(cave);
		m.update();
		var rd : Dynamic = @:privateAccess cave.driver;
		check(rd.convolver != null && rd.convolver.buffer != null, "convolver with a response");
		check(starts.length > 0, "short channel not started");
		for (s in starts) check(s.wet, "short channel started before its reverb was in the graph");

		// the same preset on another Reverb: the response is not generated again
		var again = new Reverb();
		again.decayTime = 3.8;
		var c2 = sound("click2.wav", Std.int(44100 * 0.03)).play();
		c2.addEffect(again);
		m.update();
		var rd2 : Dynamic = @:privateAccess again.driver;
		check(rd2.convolver != rd.convolver && rd2.convolver.buffer == rd.convolver.buffer, "response generated again for the same preset");
		click.stop();
		c2.stop();
		m.update();
	}

	static function main() {
		stubWebAudio();
		impulse();
		firstChannel();
		graph();
		trace("WebAudioReverbTest ok");
	}
}
