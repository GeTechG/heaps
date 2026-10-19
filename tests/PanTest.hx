// Run: haxe -cp . -cp tests -lib format --main PanTest --interp
// hxd.snd.effect.Pan mixes a channel with the StereoPannerNode law used on WebAudio, and the Manager streams a panned channel through it.
import hxd.snd.effect.Pan;
import hxd.snd.Data.SampleFormat;
import hxd.snd.Driver;

class Buf {
	public var data : haxe.io.Bytes;
	public var channels : Int;
	public var sampleStart : Int;
	public function new() {}
}

// records what the Manager queues, in place of the device
class RecordingDriver implements hxd.snd.Driver {
	public var queued = new Map<SourceHandle, Array<Buf>>();
	public var processed = new Map<SourceHandle, Int>();
	public var played = 0;
	var bufs = new Map<BufferHandle, Buf>();
	public function new() {}
	public function hasFeature(d : DriverFeature) return true;
	public function setMasterVolume(value : Float) {}
	public function setListenerParams(position : h3d.Vector, direction : h3d.Vector, up : h3d.Vector, ?velocity : h3d.Vector) {}
	public function createSource() { var s = new SourceHandle(); queued.set(s, []); processed.set(s, 0); return s; }
	public function playSource(source : SourceHandle) {}
	public function stopSource(source : SourceHandle) {}
	public function setSourceVolume(source : SourceHandle, value : Float) {}
	public function destroySource(source : SourceHandle) {}
	public function createBuffer() { var b = new BufferHandle(); bufs.set(b, new Buf()); return b; }
	public function setBufferData(buffer : BufferHandle, data : haxe.io.Bytes, size : Int, format : SampleFormat, channelCount : Int, samplingRate : Int) {
		var b = bufs.get(buffer);
		b.data = data.sub(0, size);
		b.channels = channelCount;
	}
	public function destroyBuffer(buffer : BufferHandle) {}
	public function queueBuffer(source : SourceHandle, buffer : BufferHandle, sampleStart : Int, endOfStream : Bool) {
		var b = bufs.get(buffer);
		b.sampleStart = sampleStart;
		queued.get(source).push(b);
	}
	public function unqueueBuffer(source : SourceHandle, buffer : BufferHandle) {
		queued.get(source).remove(bufs.get(buffer));
		if (processed.get(source) > 0) processed.set(source, processed.get(source) - 1);
	}
	public function getProcessedBuffers(source : SourceHandle) : Int return processed.get(source);
	public function getPlayedSampleCount(source : SourceHandle) return played;
	public function update() {}
	public function dispose() {}
	public function getEffectDriver(type : String) return new EffectDriver<Dynamic>();
}

class ConstData extends hxd.snd.Data {
	var frame : Array<Float>;
	public function new(frame : Array<Float>, samples : Int) {
		this.frame = frame;
		this.samples = samples;
		samplingRate = 44100;
		sampleFormat = I16;
		channels = frame.length;
	}
	override function decodeBuffer(out : haxe.io.Bytes, outPos : Int, sampleStart : Int, sampleCount : Int) {
		for (i in 0...sampleCount)
			for (v in frame) {
				out.setUInt16(outPos, Std.int(v * 0x8000) & 0xFFFF);
				outPos += 2;
			}
	}
}

class PanTest {

	// StereoPannerNode, https://webaudio.github.io/web-audio-api/#stereopanner-algorithm
	static function web(pan : Float, input : Array<Float>) : Array<Float> {
		if (input.length == 1) {
			var x = (pan + 1) / 2;
			return [input[0] * Math.cos(x * Math.PI / 2), input[0] * Math.sin(x * Math.PI / 2)];
		}
		var inL = input[0], inR = input[1];
		if (pan <= 0) {
			var x = pan + 1;
			return [inL + inR * Math.cos(x * Math.PI / 2), inR * Math.sin(x * Math.PI / 2)];
		}
		var x = pan;
		return [inL * Math.cos(x * Math.PI / 2), inR + inL * Math.sin(x * Math.PI / 2)];
	}

	static function near(a : Float, b : Float, eps : Float, what : String) {
		if (Math.abs(a - b) > eps) throw '$what: $a != $b';
	}

	static function frame(b : haxe.io.Bytes, i : Int) {
		inline function s16(v : Int) return (v >= 0x8000 ? v - 0x10000 : v) / 0x8000;
		return [s16(b.getUInt16(i * 4)), s16(b.getUInt16(i * 4 + 2))];
	}

	static function checkFrame(buf : Buf, i : Int, pan : Float, input : Array<Float>, what : String) {
		var got = frame(buf.data, i), want = web(pan, input);
		near(got[0], want[0], 2 / 0x8000, '$what L');
		near(got[1], want[1], 2 / 0x8000, '$what R');
	}

	static function mixSweep() {
		var input = haxe.io.Bytes.alloc(8), out = haxe.io.Bytes.alloc(8);
		for (k in 0...201) {
			var v = k / 100 - 1;
			for (src in [[0.7], [1., 0.], [0., 1.], [0.3, -0.8], [0.75, 0.75]]) {
				for (i in 0...src.length) input.setFloat(i * 4, src[i]);
				Pan.mix(input, F32, src.length, 1, v, v, out, F32);
				var want = web(v, src);
				near(out.getFloat(0), want[0], 1e-6, 'mix L at $v $src');
				near(out.getFloat(4), want[1], 1e-6, 'mix R at $v $src');
			}
		}
		// out-of-range values are clamped
		input.setFloat(0, 0.5);
		Pan.mix(input, F32, 1, 1, 3, 3, out, F32);
		near(out.getFloat(0), 0, 1e-6, "clamp");
	}

	static function sound(name : String, frame : Array<Float>) {
		var snd = new hxd.res.Sound(new hxd.fs.BytesFileSystem.BytesFileEntry(name, haxe.io.Bytes.alloc(0)));
		snd.setData(new ConstData(frame, 44100));
		return snd;
	}

	static function managerPath() {
		var m = hxd.snd.Manager.get();

		// the OpenAL emulator (the driver here) and the virtual mode (no driver) play a panned channel without failing
		for (virtual in [false, true]) {
			if (virtual) @:privateAccess m.driver = null;
			var c = sound("any.wav", [0.5, 0.25]).play(true);
			c.addEffect(new Pan(-0.5));
			for (i in 0...3) m.update();
			if (!virtual && !@:privateAccess c.source.panned) throw "emulator: channel not mixed";
			c.stop();
			m.update();
		}

		var drv = new RecordingDriver();
		@:privateAccess {
			m.driver = drv;
			m.freeStreamBuffers = [];
			m.soundBufferMap = new Map();
			m.soundBufferKeys = [];
			m.sources = [for (i in 0...hxd.snd.Manager.MAX_SOURCES) new hxd.snd.Manager.Source(drv)];
		}
		var stereo = [0.5, 0.25];
		var c = sound("stereo.wav", stereo).play(true);
		var pan = c.addEffect(new Pan(-0.5));
		m.update();
		var src = drv.queued.get(@:privateAccess c.source.handle);
		if (src.length != 1) throw "queued " + src.length;
		var b = src[0];
		if (b.channels != 2 || b.data.length != hxd.snd.Manager.PAN_BUFFER_SAMPLE_COUNT * 4) throw "mixed buffer " + b.channels + " " + b.data.length;
		checkFrame(b, 0, -0.5, stereo, "stereo at -0.5");

		m.update();
		if (src.length != hxd.snd.Manager.PAN_BUFFER_QUEUE_LENGTH) throw "queue not filled: " + src.length;

		// a change ramps from the last mixed value on the next buffer
		pan.value = 0.5;
		drv.processed.set(@:privateAccess c.source.handle, 1);
		m.update();
		var b = src[src.length - 1];
		checkFrame(b, 0, -0.5, stereo, "ramp start");
		checkFrame(b, hxd.snd.Manager.PAN_BUFFER_SAMPLE_COUNT - 1, 0.5, stereo, "ramp end");

		// 0 leaves a stereo clip as it is
		pan.value = 0;
		drv.processed.set(@:privateAccess c.source.handle, 1);
		m.update();
		var b = src[src.length - 1];
		checkFrame(b, hxd.snd.Manager.PAN_BUFFER_SAMPLE_COUNT - 1, 0, stereo, "centre");
		near(frame(b.data, hxd.snd.Manager.PAN_BUFFER_SAMPLE_COUNT - 1)[0], 0.5, 2 / 0x8000, "centre unchanged");

		// removing the pan goes back to the plain sound buffer, where the channel had got to
		c.removeEffect(pan);
		drv.played = 4410;
		m.update();
		var src = drv.queued.get(@:privateAccess c.source.handle);
		if (src.length != 1 || src[0].data.length != 44100 * 4) throw "plain buffer expected";
		if (src[0].sampleStart != 4410) throw "resumed at " + src[0].sampleStart;
		drv.played = 0;
		c.stop();

		// a mono clip comes out in stereo
		var c = sound("mono.wav", [0.5]).play(true);
		c.addEffect(new Pan(0.25));
		m.update();
		var src = drv.queued.get(@:privateAccess c.source.handle);
		if (src[0].channels != 2) throw "mono not mixed to stereo";
		checkFrame(src[0], 0, 0.25, [0.5], "mono");
		c.stop();
	}

	static function main() {
		mixSweep();
		managerPath();
		trace("PanTest ok");
	}
}
