package hxd.snd;

#if hl

private typedef OpusFile = hl.Abstract<"fmt_opus">;

/**
	Ogg Opus sound data, decoded by fmt.hdll. Opus always decodes at 48 kHz.
**/
class OpusData extends Data {

	var bytes : haxe.io.Bytes;
	var reader : OpusFile;
	var currentSample : Int;

	public function new( bytes : haxe.io.Bytes ) {
		this.bytes = bytes;
		reader = opus_open(bytes, bytes.length);
		if( reader == null ) throw "Failed to decode OPUS data";

		var b = 0, f = 0, s = 0, c = 0;
		opus_info(reader, b, f, s, c);
		channels = c;
		samples = s;
		sampleFormat = I16;
		samplingRate = f;
	}

	/**
		Tells if `bytes` hold an Ogg stream whose first packet is an Opus header.
	**/
	public static function isOpus( bytes : haxe.io.Bytes ) {
		if( bytes.length < 27 || bytes.getString(0, 4) != "OggS" )
			return false;
		var start = 27 + bytes.get(26);
		return bytes.length >= start + 8 && bytes.getString(start, 8) == "OpusHead";
	}

	override function resample(rate:Int, format:Data.SampleFormat, channels:Int):Data  {
		switch( format ) {
		case I16, F32 if( channels == this.channels && rate == this.samplingRate ):
			var g = new OpusData(bytes);
			g.sampleFormat = format;
			return g;
		default:
			return super.resample(rate, format, channels);
		}
	}

	override function decodeBuffer(out:haxe.io.Bytes, outPos:Int, sampleStart:Int, sampleCount:Int) {
		if( currentSample != sampleStart ) {
			if( !opus_seek(reader, sampleStart) ) {
				currentSample = -1; // unknown position: seek again next time
				throw "Invalid sample start";
			}
			currentSample = sampleStart;
		}
		var bpp = getBytesPerSample();
		var output : hl.Bytes = out;
		output = output.offset(outPos);
		var format = switch( sampleFormat ) {
		case I16: 2;
		case F32: 3;
		default:
			throw "assert";
		}
		var bytesNeeded = sampleCount * bpp;
		while( bytesNeeded > 0 ) {
			var read = opus_read(reader, output, bytesNeeded, format);
			if( read < 0 ) {
				currentSample = -1;
				throw "Failed to decode OPUS data";
			}
			if( read == 0 ) {
				// EOF
				output.fill(0, bytesNeeded, 0);
				break;
			}
			bytesNeeded -= read;
			output = output.offset(read);
		}
		currentSample += sampleCount;
	}

	@:hlNative("fmt", "opus_open") static function opus_open( bytes : hl.Bytes, size : Int ) : OpusFile {
		return null;
	}

	@:hlNative("fmt", "opus_seek") static function opus_seek( o : OpusFile, sample : Int ) : Bool {
		return false;
	}

	@:hlNative("fmt", "opus_info") static function opus_info( o : OpusFile, bitrate : hl.Ref<Int>, freq : hl.Ref<Int>, samples : hl.Ref<Int>, channels : hl.Ref<Int> ) : Void {
	}

	@:hlNative("fmt", "opus_read") static function opus_read( o : OpusFile, output : hl.Bytes, size : Int, format : Int ) : Int {
		return 0;
	}

}

#else

class OpusData extends Data {

	public function new( bytes : haxe.io.Bytes ) {
		throw "Ogg Opus decoding requires HashLink";
	}

	override function decodeBuffer(out:haxe.io.Bytes, outPos:Int, sampleStart:Int, sampleCount:Int) {
		throw "Ogg Opus decoding requires HashLink";
	}

}

#end
