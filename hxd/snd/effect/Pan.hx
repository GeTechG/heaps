package hxd.snd.effect;

/**
	Stereo pan of a channel: `value` from -1 (fully left) to 1 (fully right), 0 is the centre.
	Follows the equal-power law of WebAudio `StereoPannerNode`; on a stereo clip 0 leaves both channels as they are.
	WebAudio pans with a `StereoPannerNode`. Other drivers get the channel as short stereo buffers mixed by `mix`,
	so a change of `value` is heard after the buffers already queued (`Manager.PAN_BUFFER_SAMPLE_COUNT` × `Manager.PAN_BUFFER_QUEUE_LENGTH` samples).
**/
class Pan extends hxd.snd.Effect {
	public var value : Float;

	public function new(value = 0.) {
		super("pan");
		this.value = value;
	}

	/**
		Mixes `samples` frames of `input` (`channels` 1 or 2, interleaved, `format`) into stereo `out` (`outFormat`),
		with the pan going linearly from `from` to `to` over the frames. A stereo clip panned to a side sums both
		channels, up to twice full scale: an integer `outFormat` clips it.
	**/
	public static function mix( input : haxe.io.Bytes, format : hxd.snd.Data.SampleFormat, channels : Int, samples : Int, from : Float, to : Float, out : haxe.io.Bytes, outFormat : hxd.snd.Data.SampleFormat ) {
		from = clamp(from);
		to = clamp(to);
		var fbytes = hxd.snd.Data.formatBytes(format), obytes = hxd.snd.Data.formatBytes(outFormat);
		var r = 0, w = 0;
		var ll = 0., rl = 0., lr = 0., rr = 0.;
		for( i in 0...samples ) {
			if( i == 0 || from != to ) {
				// gains from input L/R to output L/R, StereoPannerNode: https://webaudio.github.io/web-audio-api/#stereopanner-algorithm
				var v = samples > 1 ? from + (to - from) * i / (samples - 1) : to;
				if( channels == 1 ) {
					var a = (v + 1) * Math.PI / 4;
					ll = Math.cos(a);
					lr = Math.sin(a);
				} else if( v <= 0 ) {
					var a = (v + 1) * Math.PI / 2;
					ll = 1; lr = 0; rl = Math.cos(a); rr = Math.sin(a);
				} else {
					var a = v * Math.PI / 2;
					ll = Math.cos(a); lr = Math.sin(a); rl = 0; rr = 1;
				}
			}
			var sl = read(input, r, format);
			var sr = channels == 1 ? 0. : read(input, r + fbytes, format);
			r += fbytes * channels;
			write(out, w, outFormat, sl * ll + sr * rl);
			write(out, w + obytes, outFormat, sl * lr + sr * rr);
			w += obytes * 2;
		}
	}

	static inline function read( b : haxe.io.Bytes, pos : Int, format : hxd.snd.Data.SampleFormat ) : Float {
		return switch( format ) {
		case UI8: (b.get(pos) - 128) / 128;
		case I16: var v = b.getUInt16(pos); (v >= 0x8000 ? v - 0x10000 : v) / 0x8000;
		case F32: b.getFloat(pos);
		}
	}

	static inline function write( b : haxe.io.Bytes, pos : Int, format : hxd.snd.Data.SampleFormat, v : Float ) {
		switch( format ) {
		case UI8:
			var i = Math.round(v * 128) + 128;
			b.set(pos, i < 0 ? 0 : i > 255 ? 255 : i);
		case I16:
			var i = Math.round(v * 0x8000);
			b.setUInt16(pos, (i < -0x8000 ? -0x8000 : i > 0x7FFF ? 0x7FFF : i) & 0xFFFF);
		case F32:
			b.setFloat(pos, v);
		}
	}

	static inline function clamp( v : Float ) {
		return v < -1 ? -1 : v > 1 ? 1 : v;
	}
}
