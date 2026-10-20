// Run: haxe -cp . -cp tests -lib format --main NoDeviceTest --interp
// hxd.snd.Manager plays every channel virtually when its driver cannot open a device, whatever the driver throws.
import hxd.snd.Data.SampleFormat;
import hxd.snd.Driver;

// a driver that opens no device: it throws from the constructor or, once created, from createSource
class FailingDriver implements hxd.snd.Driver {
	public static var disposed = 0;
	public function new(failInCreateSource : Bool) {
		if (!failInCreateSource) throw new haxe.Exception("no audio device");
	}
	public function hasFeature(d : DriverFeature) return true;
	public function setMasterVolume(value : Float) {}
	public function setListenerParams(position : h3d.Vector, direction : h3d.Vector, up : h3d.Vector, ?velocity : h3d.Vector) {}
	public function createSource() : SourceHandle throw new haxe.Exception("could not create source");
	public function playSource(source : SourceHandle) {}
	public function stopSource(source : SourceHandle) {}
	public function setSourceVolume(source : SourceHandle, value : Float) {}
	public function destroySource(source : SourceHandle) {}
	public function createBuffer() : BufferHandle throw "unused";
	public function setBufferData(buffer : BufferHandle, data : haxe.io.Bytes, size : Int, format : SampleFormat, channelCount : Int, samplingRate : Int) {}
	public function destroyBuffer(buffer : BufferHandle) {}
	public function queueBuffer(source : SourceHandle, buffer : BufferHandle, sampleStart : Int, endOfStream : Bool) {}
	public function unqueueBuffer(source : SourceHandle, buffer : BufferHandle) {}
	public function getProcessedBuffers(source : SourceHandle) : Int return 0;
	public function getPlayedSampleCount(source : SourceHandle) : Int return 0;
	public function update() {}
	public function dispose() disposed++;
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

class NoDeviceTest {

	static function check(what : String, failInCreateSource : Bool) {
		@:privateAccess hxd.snd.Manager.createDriver = () -> new FailingDriver(failInCreateSource);
		@:privateAccess hxd.snd.Manager.instance = null;
		var m = hxd.snd.Manager.get();
		if (@:privateAccess m.driver != null) throw '$what: driver kept';
		if (m.driverError == null) throw '$what: no driverError';
		Sys.println('$what: driverError = ${m.driverError.message}');

		var snd = new hxd.res.Sound(new hxd.fs.BytesFileSystem.BytesFileEntry("any.wav", haxe.io.Bytes.alloc(0)));
		snd.setData(new SilentData(441)); // 10 ms
		var c = snd.play();
		var ended = false;
		c.onEnd = () -> ended = true;
		m.timeOffset = 0.001;
		var start = haxe.Timer.stamp();
		while (!ended && haxe.Timer.stamp() - start < 2) {
			m.update();
			if (!@:privateAccess c.isVirtual) throw '$what: channel not virtual';
		}
		if (!ended) throw '$what: channel did not end';
		m.dispose();
	}

	static function main() {
		check("constructor throws", false);
		check("createSource throws", true);
		if (FailingDriver.disposed != 1) throw "driver not disposed: " + FailingDriver.disposed;
		Sys.println("ok");
	}
}
