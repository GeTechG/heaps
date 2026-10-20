// Run (needs an fmt.hdll built with Opus, hashlink 193d8631 or later): haxe -cp . -cp tests -lib format --main OpusDataTest -hl test.hl && hl test.hl && haxe -cp . -cp tests -lib format --main OpusDataTest -dce full --js test.js && ! grep hxd_snd_OpusData test.js && node test.js
// hxd.snd.OpusData decodes Ogg Opus on HashLink, whole or by chunks, and hxd.res.Sound picks it for Opus resources only.
class OpusDataTest {

	static function main() {
		#if hl
		for( clip in [{ name : "mono", channels : 1 }, { name : "stereo", channels : 2 }] ) {
			var bytes = sys.io.File.getBytes("tests/opus/" + clip.name + ".opus");
			var ref = sys.io.File.getBytes("tests/opus/" + clip.name + ".s16");
			var data = new hxd.snd.OpusData(bytes);
			check(clip.name + " info", data.samples == 12000 && data.channels == clip.channels && data.samplingRate == 48000 && data.sampleFormat == I16);
			var bpp = data.getBytesPerSample();

			var whole = haxe.io.Bytes.alloc(data.samples * bpp);
			data.decode(whole, 0, 0, data.samples);
			check(clip.name + " s16 matches opusdec", maxDiff(whole, ref, 2, s16) <= 16); // op_read dithers, the reference does not

			var chunks = haxe.io.Bytes.alloc(data.samples * bpp);
			var chunked = new hxd.snd.OpusData(bytes);
			var pos = 0;
			while( pos < data.samples ) {
				var count = hxd.Math.imin(700, data.samples - pos);
				chunked.decode(chunks, pos * bpp, pos, count);
				pos += count;
			}
			check(clip.name + " chunks equal whole", chunks.compare(whole) == 0);

			// after a seek the decoder is not bit-exact (opusfile pre-rolls it), but it must land on the right sample
			var seek = haxe.io.Bytes.alloc(1000 * bpp);
			chunked.decode(seek, 0, 6000, 1000);
			var near = [for( o in -1...2 ) rmsDiff(seek, whole.sub((6000 + o) * bpp, 1000 * bpp))];
			check(clip.name + " seek", near[1] < 64 && near[1] < near[0] && near[1] < near[2]);

			var tail = haxe.io.Bytes.alloc(400 * bpp);
			tail.fill(0, tail.length, 0x55);
			chunked.decode(tail, 0, data.samples - 200, 400);
			check(clip.name + " silence past the end", rmsDiff(tail.sub(0, 200 * bpp), whole.sub((data.samples - 200) * bpp, 200 * bpp)) < 64 && isZero(tail.sub(200 * bpp, 200 * bpp)));

			var f32 = data.resample(48000, F32, clip.channels);
			check(clip.name + " resample to F32", Std.isOfType(f32, hxd.snd.OpusData) && f32.sampleFormat == F32);
			var floats = haxe.io.Bytes.alloc(data.samples * f32.getBytesPerSample());
			f32.decode(floats, 0, 0, data.samples);
			check(clip.name + " f32 matches opusdec", maxDiff(floats, ref, 4, (b, i) -> b.getFloat(i) * 32768) <= 1.5);

			var res = hxd.res.Any.fromBytes(clip.name + ".opus", bytes).toSound();
			check(clip.name + " resource is Opus", Std.isOfType(res.getData(), hxd.snd.OpusData));
		}

		// an Ogg stream whose first packet is not OpusHead still goes to OggData
		var vorbis = haxe.io.Bytes.alloc(64);
		vorbis.blit(0, haxe.io.Bytes.ofString("OggS"), 0, 4);
		vorbis.set(26, 1);
		vorbis.blit(28, haxe.io.Bytes.ofString("\x01vorbis"), 0, 7);
		var msg = null;
		try hxd.res.Any.fromBytes("a.ogg", vorbis).toSound().getData() catch( e : String ) msg = e;
		check("other Ogg goes to OggData", msg == "Failed to decode OGG data");
		check("supportedFormat", hxd.res.Sound.supportedFormat(OggOpus));
		#else
		var snd = hxd.res.Any.fromBytes("a.wav", haxe.io.Bytes.ofString("RIFF")).toSound();
		if( Math.random() < 0 ) snd.play(); // keeps the decoding path in the DCE graph; no audio device under node
		check("supportedFormat", !hxd.res.Sound.supportedFormat(OggOpus));
		#end
		trace("ok");
	}

	static function s16( b : haxe.io.Bytes, i : Int ) : Float {
		var v = b.getUInt16(i);
		return v >= 0x8000 ? v - 0x10000 : v;
	}

	static function maxDiff( a : haxe.io.Bytes, ref : haxe.io.Bytes, bpv : Int, get : (haxe.io.Bytes, Int) -> Float ) {
		var max = 0.;
		for( k in 0...Std.int(a.length / bpv) ) {
			var d = Math.abs(get(a, k * bpv) - s16(ref, k * 2));
			if( d > max ) max = d;
		}
		return max;
	}

	static function rmsDiff( a : haxe.io.Bytes, b : haxe.io.Bytes ) {
		var sum = 0.;
		for( k in 0...a.length >> 1 ) {
			var d = s16(a, k * 2) - s16(b, k * 2);
			sum += d * d;
		}
		return Math.sqrt(sum / (a.length >> 1));
	}

	static function isZero( b : haxe.io.Bytes ) {
		for( i in 0...b.length )
			if( b.get(i) != 0 ) return false;
		return true;
	}

	static function check( what : String, ok : Bool ) {
		if( !ok ) throw "FAIL: " + what;
	}

}
