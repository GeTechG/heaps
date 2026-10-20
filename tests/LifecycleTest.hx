// Run: haxe -cp . -cp tests -lib format --main LifecycleTest --interp
// hxd.snd.Manager.paused freezes the mix and resumes every channel where it stopped; the background pause leaves a game's own pause alone.
import hxd.snd.Data.SampleFormat;
import hxd.snd.Driver;

// a driver that records what the Manager asks of it
class RecordingDriver implements hxd.snd.Driver {
	public var queued = 0;
	public var played = 0;
	public var stopped = 0;
	public function new() {}
	public function hasFeature(d : DriverFeature) return true;
	public function setMasterVolume(value : Float) {}
	public function setListenerParams(position : h3d.Vector, direction : h3d.Vector, up : h3d.Vector, ?velocity : h3d.Vector) {}
	public function createSource() : SourceHandle return new SourceHandle();
	public function playSource(source : SourceHandle) played++;
	public function stopSource(source : SourceHandle) stopped++;
	public function setSourceVolume(source : SourceHandle, value : Float) {}
	public function destroySource(source : SourceHandle) {}
	public function createBuffer() : BufferHandle return new BufferHandle();
	public function setBufferData(buffer : BufferHandle, data : haxe.io.Bytes, size : Int, format : SampleFormat, channelCount : Int, samplingRate : Int) {}
	public function destroyBuffer(buffer : BufferHandle) {}
	public function queueBuffer(source : SourceHandle, buffer : BufferHandle, sampleStart : Int, endOfStream : Bool) queued++;
	public function unqueueBuffer(source : SourceHandle, buffer : BufferHandle) {}
	public function getProcessedBuffers(source : SourceHandle) : Int return 0;
	public function getPlayedSampleCount(source : SourceHandle) : Int return 0;
	public function update() {}
	public function dispose() {}
	public function getEffectDriver(type : String) return new EffectDriver<Dynamic>();
}

class SilentData extends hxd.snd.Data {
	public function new(samples : Int) {
		this.samples = samples;
		samplingRate = 44100;
		sampleFormat = I16;
		channels = 1;
	}
	override function decodeBuffer(out : haxe.io.Bytes, outPos : Int, sampleStart : Int, sampleCount : Int) {
		out.fill(outPos, sampleCount * 2, 0);
	}
}

class LifecycleTest {

	static function sound(seconds : Float) {
		var snd = new hxd.res.Sound(new hxd.fs.BytesFileSystem.BytesFileEntry("any.wav", haxe.io.Bytes.alloc(0)));
		snd.setData(new SilentData(Std.int(44100 * seconds)));
		return snd;
	}

	static function manager(driver : Driver) {
		@:privateAccess hxd.snd.Manager.createDriver = () -> driver;
		@:privateAccess hxd.snd.Manager.instance = null;
		return hxd.snd.Manager.get();
	}

	static function run(m : hxd.snd.Manager, seconds : Float) {
		var end = haxe.Timer.stamp() + seconds;
		while (haxe.Timer.stamp() < end) {
			m.update();
			Sys.sleep(0.005);
		}
	}

	static function near(what : String, v : Float, expected : Float, tolerance : Float) {
		if (Math.abs(v - expected) > tolerance) throw '$what: $v, expected $expected';
	}

	// a virtual channel does not advance while paused, and goes on from there
	static function virtualChannel() {
		var m = manager(null);
		var c = sound(10).play();
		run(m, 0.2);
		var pos = c.position;
		m.paused = true;
		run(m, 0.3);
		near("position while paused", c.position, pos, 0.001);
		var late = sound(10).play(); // played during the pause: starts on resume
		Sys.sleep(0.2);
		m.paused = false;
		m.update();
		near("position on resume", c.position, pos, 0.03);
		near("channel played while paused", late.position, 0, 0.03);
		run(m, 0.2);
		near("position after resume", c.position, pos + 0.2, 0.05);
		m.dispose();
	}

	// a channel on a device is neither queued nor started while paused; a fade does not advance
	static function deviceChannel() {
		var d = new RecordingDriver();
		var m = manager(d);
		m.paused = true;
		var c = sound(10).play();
		run(m, 0.1);
		if (d.queued != 0 || d.played != 0) throw 'paused: ${d.queued} buffers queued, ${d.played} sources played';
		m.paused = false;
		m.update();
		if (d.queued == 0 || d.played == 0) throw "not started on resume";
		// a driver without a device pause: the channel gives up its source and gets one again on resume
		var played = d.played;
		m.paused = true;
		if (d.stopped != 1 || @:privateAccess c.source != null) throw 'source not released on pause: ${d.stopped} stopped';
		m.paused = false;
		m.update();
		if (d.played != played + 1 || @:privateAccess c.source == null) throw "source not bound again on resume";

		c.fadeTo(0, 1);
		run(m, 0.2);
		var vol = c.volume;
		m.paused = true;
		run(m, 0.3);
		near("fade while paused", c.volume, vol, 0.001);
		m.paused = false;
		m.update();
		near("fade on resume", c.volume, vol, 0.03);
		run(m, 0.2);
		if (c.volume >= vol - 0.1) throw 'fade did not go on after resume: ${c.volume}, was $vol';
		m.dispose();
	}

	// a queued sound already buffered behind the current one still plays after a pause that released the source
	static function queuedSound() @:privateAccess {
		var m = manager(new RecordingDriver());
		var c = sound(0.1).play();
		var next = sound(0.1);
		c.queueSound(next);
		run(m, 0.05);
		if (c.queue.length != 0 || c.source == null || c.source.nextSounds[0] != next) throw "the queued sound was not buffered";
		m.paused = true;
		if (c.queue.length != 1 || c.queue[0] != next) throw "the buffered queued sound was lost on pause";
		m.paused = false;
		run(m, 0.05);
		if (c.queue.length != 0 || c.source.nextSounds.length != 1 || c.source.nextSounds[0] != next) throw "the queued sound is not buffered once after resume";
		m.dispose();
	}

	// a channel group's fade does not advance while paused either
	static function groupFade() {
		var m = manager(new RecordingDriver());
		var g = new hxd.snd.ChannelGroup("music");
		sound(10).play(g);
		g.fadeTo(0, 1);
		run(m, 0.2);
		var vol = g.volume;
		m.paused = true;
		Sys.sleep(1.2);
		m.paused = false;
		m.update();
		near("group fade on resume", g.volume, vol, 0.03);
		m.dispose();
	}

	static function background() @:privateAccess {
		var m = manager(null);
		m.onBackground(true);
		if (!m.paused) throw "not paused in the background";
		m.onBackground(false);
		if (m.paused) throw "not resumed on return";

		m.paused = true;
		m.onBackground(true);
		m.onBackground(false);
		if (!m.paused) throw "the game's pause was undone on return";

		m.paused = false;
		m.onBackground(true);
		m.paused = true; // the game pauses in the background too
		m.onBackground(false);
		if (!m.paused) throw "the game's pause in the background was undone on return";
		m.dispose();
	}

	static function main() {
		virtualChannel();
		deviceChannel();
		groupFade();
		queuedSound();
		background();
		Sys.println("ok");
	}
}
