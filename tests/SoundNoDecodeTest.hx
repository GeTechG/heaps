// Run: haxe -cp . -cp tests -lib format --main SoundNoDecodeTest -dce full -D heaps_no_sound_decode --js test.js && ! grep -E 'hxd_snd_WavData|hxd_snd_Mp3Data|format_mp3|format_wav' test.js && node test.js
// With -D heaps_no_sound_decode, hxd.res.Sound plays data set beforehand and keeps no sound decoder in the output.
class SoundNoDecodeTest {

	static function main() {
		var snd = new hxd.res.Sound(new hxd.fs.BytesFileSystem.BytesFileEntry("a.wav", haxe.io.Bytes.ofString("RIFF")));
		var msg = null;
		try snd.getData() catch( e : String ) msg = e;
		if( msg != "Sound has no data a.wav" ) throw "getData without data: " + msg;
		var data = new hxd.snd.LoadingData(snd);
		snd.setData(data);
		if( snd.getData() != data ) throw "setData";
		if( Math.random() < 0 ) snd.play(); // keeps the play path in the DCE graph; no audio device under node
		trace("ok");
	}

}
