// Run: haxe -cp . -cp tests -lib format --main VirtualPitchTest --interp
// hxd.snd.Manager advances a virtual channel's position at the rate of its Pitch effect (or its channel group's).
import hxd.snd.effect.Pitch;

class SilentSound extends hxd.snd.Data {
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

class VirtualPitchTest {

	static var m : hxd.snd.Manager;

	static function sound(seconds : Float) {
		var snd = new hxd.res.Sound(new hxd.fs.BytesFileSystem.BytesFileEntry("any.wav", haxe.io.Bytes.alloc(0)));
		snd.setData(new SilentSound(Std.int(seconds * 44100)));
		return snd;
	}

	// a virtual channel that has run `elapsed` seconds since the last update: its position afterwards
	static function advance(channelPitch : Null<Float>, groupPitch : Null<Float>, elapsed : Float) : Float {
		var g = new hxd.snd.ChannelGroup("test");
		if (groupPitch != null) g.addEffect(new Pitch(groupPitch));
		var c = sound(10).play(false, 1., g);
		if (channelPitch != null) c.addEffect(new Pitch(channelPitch));
		@:privateAccess c.lastStamp = haxe.Timer.stamp() - elapsed;
		m.update();
		var p = c.position;
		c.stop();
		return p;
	}

	static function expect(what : String, got : Float, want : Float) {
		// the update reads the clock a little after the test did
		if (got < want - 1e-6 || got > want + 0.05) throw '$what: position $got, expected $want';
		Sys.println('$what: $got');
	}

	static function main() {
		@:privateAccess hxd.snd.Manager.createDriver = () -> throw new haxe.Exception("no audio device");
		m = hxd.snd.Manager.get();
		if (@:privateAccess m.driver != null) throw "driver kept";

		expect("pitch on the channel", advance(2, null, 0.5), 1.0);
		expect("pitch on the channel group", advance(null, 0.5, 1.0), 0.5);
		expect("channel pitch over the group's", advance(2, 0.5, 0.5), 1.0);
		expect("no pitch", advance(null, null, 0.5), 0.5);
		expect("negative pitch", advance(-1, null, 0.5), 0.0);

		// end at pitch: a 1 s sound at pitch 2 ends after 0.5 s
		var c = sound(1).play();
		c.addEffect(new Pitch(2));
		var ended = false;
		c.onEnd = () -> ended = true;
		@:privateAccess c.lastStamp = haxe.Timer.stamp() - 0.45;
		m.update();
		if (ended) throw "end at pitch: ended before 0.5 s";
		@:privateAccess c.lastStamp -= 0.06;
		m.update();
		if (!ended) throw "end at pitch: not ended after 0.5 s";
		Sys.println("end at pitch: ok");

		m.dispose();
		Sys.println("ok");
	}
}
