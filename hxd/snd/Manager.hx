package hxd.snd;

import hxd.snd.Driver;
import haxe.MainLoop;
import hxd.snd.effect.Pan;

@:access(hxd.snd.Manager)
class Source {
	static var ID = 0;

	public var id (default, null) : Int;
	public var handle  : SourceHandle;
	public var channel : Channel;
	public var buffers : Array<Buffer>;

	public var volume  = -1.0;
	public var playing = false;
	public var start   = 0;

	public var streamSound : hxd.res.Sound;
	public var streamBuffer : haxe.io.Bytes;
	public var streamStart : Int;
	public var streamPos : Int;

	// mixed by the Manager into stereo buffers (Pan.mix), from panValue on
	public var panned   = false;
	public var panValue = 0.;

	// what follows each sound end queued so far: the sound taken from the channel's queue, null for a loop restart
	public var nextSounds : Array<hxd.res.Sound> = [];

	public function new(driver : Driver) {
		id      = ID++;
		handle  = driver.createSource();
		buffers = [];
	}

	public function dispose() {
		Manager.get().driver.destroySource(handle);
	}
}

@:access(hxd.snd.Manager)
class Buffer {
	public var handle   : BufferHandle;
	public var sound    : hxd.res.Sound;
	public var isEnd    : Bool;
	public var isStream : Bool;
	public var refs     : Int;
	public var lastStop : Float;

	public var start      : Int;
	public var end        : Int = 0;
	public var samples    : Int;
	public var sampleRate : Int;

	public function new(driver : Driver) {
		handle = driver.createBuffer();
		refs = 0;
		lastStop = haxe.Timer.stamp();
	}

	public function dispose() {
		Manager.get().driver.destroyBuffer(handle);
	}
}

class Manager {
	// Automatically set the channel to streaming mode if its duration exceed this value.
	public static var STREAM_DURATION            = 5.;
	public static var STREAM_BUFFER_SAMPLE_COUNT = 44100;
	public static var BUFFER_QUEUE_LENGTH        = 2;
	public static var MAX_SOURCES                = 16;
	public static var SOUND_BUFFER_CACHE_SIZE    = 256;
	public static var VIRTUAL_VOLUME_THRESHOLD   = 1e-5;

	/**
		A channel with a `hxd.snd.effect.Pan` is mixed into stereo buffers of this many samples, this many queued:
		a change of the pan is heard after them. Not used with WebAudio, which pans natively.
	**/
	public static var PAN_BUFFER_SAMPLE_COUNT    = 2048;
	public static var PAN_BUFFER_QUEUE_LENGTH    = 3;
	static inline var NATIVE_PAN = #if (js && !useal) true #else false #end;
	// float keeps the headroom of the pan sum until the source gain applies; elsewhere the mix clips at full scale
	static inline var PAN_FLOAT  = #if (js || hlopenal) true #else false #end;

	/**
		Allows to decode big streaming buffers over X split frames. 0 to disable
	**/
	public static var BUFFER_STREAM_SPLIT        = 16;

	static var instance : Manager;

	public var masterVolume	: Float;
	public var masterSoundGroup   (default, null) : SoundGroup;
	public var masterChannelGroup (default, null) : ChannelGroup;
	public var listener : Listener;
	public var timeOffset : Float = 0.;

	var updateEvent   : MainEvent;

	var cachedBytes   : haxe.io.Bytes;
	var resampleBytes : haxe.io.Bytes;
	var panBytes      : haxe.io.Bytes;

	var driver   : Driver;
	var channels : Channel;
	var sources  : Array<Source>;
	var now      : Float;

	var soundBufferCount  : Int;
	var soundBufferMap    : Map<String, Buffer>;
	var soundBufferKeys	  : Array<String>;
	var freeStreamBuffers : Array<Buffer>;
	var effectGC          : Array<Effect>;
	var hasMasterVolume   : Bool;

	public var suspended : Bool = false;
	/**
		Pauses the whole mix while `true`: the device stops playing (OpenAL: `ALC_SOFT_pause_device`; elsewhere every channel
		gives up its source, to get one again on resume) and `update` neither queues buffers nor advances virtual channels and fades. Set back to `false`, every channel and fade goes on from where it was;
		a channel played meanwhile starts then. Unlike `suspended`, which leaves the device playing and virtual channels running.
		On HashLink the Manager pauses itself while the application is in the background (`hxd.System.isInBackground`).
	**/
	public var paused(default, set) : Bool = false;
	var pauseStamp : Float;
	var pausedInBackground : Bool = false;
	#if hl
	var backgroundListener : Bool -> Void;
	#end
	/**
		The exception thrown while the sound driver was created, which left the Manager without a driver: every channel then plays virtually. `null` when the driver was created.
	**/
	public var driverError(default, null) : haxe.Exception;

	static dynamic function createDriver() : Driver {
		#if usesys
		return new haxe.AudioTypes.SoundDriver();
		#elseif (js && !useal)
		return new hxd.snd.webaudio.Driver();
		#else
		return new hxd.snd.openal.Driver();
		#end
	}

	private function new() {
		try {
			driver = createDriver();
			// alloc sources
			sources = [];
			for (i in 0...MAX_SOURCES) sources.push(new Source(driver));
		} catch(e : haxe.Exception) {
			// no audio device: play every channel virtually
			driverError = e;
			if (driver != null) try driver.dispose() catch(_e) {}
			driver  = null;
			sources = [];
		}

		masterVolume       = 1.0;
		hasMasterVolume    = driver == null ? true : driver.hasFeature(MasterVolume);
		masterSoundGroup   = new SoundGroup  ("master");
		masterChannelGroup = new ChannelGroup("master");
		listener           = new Listener();
		soundBufferMap     = new Map();
		soundBufferKeys	   = [];
		freeStreamBuffers  = [];
		effectGC           = [];
		soundBufferCount   = 0;

		cachedBytes   = haxe.io.Bytes.alloc(4 * 3 * 2);
		resampleBytes = haxe.io.Bytes.alloc(STREAM_BUFFER_SAMPLE_COUNT * 2);
	}

	function getTmpBytes(size) {
		if (cachedBytes.length < size)
			cachedBytes = haxe.io.Bytes.alloc(size);
		return cachedBytes;
	}

	function getResampleBytes(size : Int) {
		if (resampleBytes.length < size)
			resampleBytes = haxe.io.Bytes.alloc(size);
		return resampleBytes;
	}

	public static function get() : Manager {
		if( instance == null ) {
			instance = new Manager();
			instance.updateEvent = haxe.MainLoop.add(instance.update);
			#if hl
			instance.backgroundListener = instance.onBackground;
			hxd.System.addBackgroundListener(instance.backgroundListener);
			if (hxd.System.isInBackground) instance.onBackground(true);
			#end
			instance.updateEvent.isBlocking = false;
		}
		return instance;
	}

	public function stopAll() {
		while( channels != null )
			channels.stop();
	}

	public function stopAllNotLooping() {
		var c = channels;
		while( c != null ) {
			var n = c.next;
			if( !c.loop ) c.stop();
			c = n;
		}
	}

	public function stopByName( name : String ) {
		var c = channels;
		while( c != null ) {
			var n = c.next;
			if( c.soundGroup != null && c.soundGroup.name == name ) c.stop();
			c = n;
		}
	}

	/**
		Returns iterator with all active instances of a Sound at the call time.
	**/
	public function getAll( sound : hxd.res.Sound ) : Iterator<Channel> {
		var ch = channels;
		var result = new Array<Channel>();
		while ( ch != null ) {
			if ( ch.sound == sound )
				result.push(ch);
			ch = ch.next;
		}
		return new hxd.impl.ArrayIterator(result);
	}

	public function cleanCache() {
		var i = 0;
		while (i < soundBufferKeys.length) {
			var k = soundBufferKeys[i];
			var b = soundBufferMap.get(k);
			i++;
			if (b.refs > 0) continue;
			soundBufferMap.remove(k);
			soundBufferKeys.remove(k);
			i--;
			b.dispose();
			--soundBufferCount;
		}
	}

	public function dispose() {
		stopAll();

		if (driver != null) {
			for (s in sources)           s.dispose();
			for (b in soundBufferMap)    b.dispose();
			for (b in freeStreamBuffers) b.dispose();
			for (e in effectGC)          e.driver.release();
			driver.dispose();
		}

		sources           = null;
		soundBufferMap    = null;
		soundBufferKeys   = null;
		freeStreamBuffers = null;
		effectGC          = null;

		updateEvent.stop();
		#if hl
		hxd.System.removeBackgroundListener(backgroundListener);
		#end
		instance = null;
	}

	public function play(sound : hxd.res.Sound, ?channelGroup : ChannelGroup, ?soundGroup : SoundGroup) {
		if (soundGroup   == null) soundGroup   = masterSoundGroup;
		if (channelGroup == null) channelGroup = masterChannelGroup;

		var sdat = sound.getData();
		if( sdat.samples == 0 ) throw sound + " has no samples";

		var c = new Channel();
		c.sound        = sound;
		c.duration     = sdat.duration;
		c.manager      = this;
		c.soundGroup   = soundGroup;
		c.channelGroup = channelGroup;
		c.next         = channels;
		c.isLoading    = sdat.isLoading();
		c.isVirtual    = driver == null;
		c.lastStamp    = paused ? pauseStamp : haxe.Timer.stamp();

		channels = c;
		return c;
	}

	function updateVirtualChannels(now : Float) {
		var c = channels;
		while (c != null) {
			if (c.pause || !c.isVirtual || c.isLoading) {
				c = c.next;
				continue;
			}

			c.position += Math.max(now - c.lastStamp, 0.0);
			c.lastStamp = now;

			var next = c.next; // save next, since we might release this channel
			while (c.position >= c.duration) {
				c.position -= c.duration;
				c.onEnd();

				// if we have released the next channel, let's stop here
				if( next != null && next.manager == null )
					next = null;

				if (c.queue.length > 0) {
					c.sound = c.queue.shift();
					c.duration = c.sound.getData().duration;
				} else if (!c.loop) {
					releaseChannel(c);
					break;
				}
			}

			c = next;
		}
	}

	function set_paused(v : Bool) {
		// the game's own choice: no longer resumed on return from the background
		pausedInBackground = false;
		if (v == paused) return v;
		paused = v;
		var now = haxe.Timer.stamp();
		if (v)
			pauseStamp = now;
		else {
			// move every stamp past the pause, one taken during the pause to its end
			inline function shift(t : Float) return t < now ? t + (now - Math.max(t, pauseStamp)) : t;
			var groups = [masterChannelGroup];
			var c = channels;
			while (c != null) {
				c.lastStamp = shift(c.lastStamp);
				if (c.currentFade != null) c.currentFade.start = shift(c.currentFade.start);
				if (groups.indexOf(c.channelGroup) < 0) groups.push(c.channelGroup);
				c = c.next;
			}
			for (g in groups)
				if (g.currentFade != null) g.currentFade.start = shift(g.currentFade.start);
			if (sources != null)
				for (s in sources)
					for (b in s.buffers)
						b.lastStop = shift(b.lastStop);
		}
		if (driver != null && !pauseDevice(v) && v)
			// no device pause: stop every source, the channels keep their positions and get a source again on resume
			for (s in sources) releaseSource(s);
		return v;
	}

	function pauseDevice(v : Bool) : Bool {
		#if !(usesys || (js && !useal))
		var al = Std.downcast(driver, hxd.snd.openal.Driver);
		if (al != null) return al.setPaused(v);
		#elseif (js && !useal)
		// no device pause on WebAudio, but the tails of the effects have to stop with the mix
		var web = Std.downcast(driver, hxd.snd.webaudio.Driver);
		if (web != null) web.setEffectsPaused(v);
		#end
		return false;
	}

	function onBackground(background : Bool) {
		if (background) {
			if (!paused) {
				paused = true;
				pausedInBackground = true;
			}
		} else if (pausedInBackground)
			paused = false;
	}

	public function update() {
		if (paused) return;
		if( timeOffset != 0 ) {
			var c = channels;
			while( c != null ) {
				c.lastStamp += timeOffset;
				if( c.currentFade != null ) c.currentFade.start += timeOffset;
				c = c.next;
			}
			for( s in sources )
				for( b in s.buffers )
					b.lastStop += timeOffset;
			timeOffset = 0;
		}
		now = haxe.Timer.stamp();

		if (driver == null) {
			updateVirtualChannels(now);
			return;
		}

		// --------------------------------------------------------------------
		// (de)queue buffers, sync positions & release ended channels
		// --------------------------------------------------------------------

		for (s in sources) {
			var c = s.channel;
			if (c == null) continue;

			// did the user changed the position?
			if (c.positionChanged) {
				releaseSource(s);
				continue;
			}

			// process consumed buffers
			var lastBuffer = null;
			var count = driver.getProcessedBuffers(s.handle);
			for (i in 0...count) {
				var b = unqueueBuffer(s);
				if( b == null ) continue;
				lastBuffer = b;
				if (b.isEnd) {
					s.nextSounds.shift();
					c.sound           = b.sound;
					c.duration        = b.sound.getData().duration;
					c.position        = c.duration;
					c.positionChanged = false;
					c.onEnd();
					s.start = 0;
				}
			}

			// did the source consumed all buffers?
			if (s.buffers.length == 0) {
				if (!lastBuffer.isEnd) {
					c.position = (lastBuffer.start + lastBuffer.samples) / lastBuffer.sampleRate;
					releaseSource(s);
				} else if (c.queue.length > 0) {
					c.sound    = c.queue.shift();
					c.duration = c.sound.getData().duration;
					c.position = 0;
					releaseSource(s);
				} else if (c.loop) {
					c.position = 0;
					releaseSource(s);
				} else {
					releaseChannel(c);
				}
				continue;
			}

			// sync channel position
			c.sound    = s.buffers[0].sound;
			c.duration = c.sound.getData().duration;

			var playedSamples = driver.getPlayedSampleCount(s.handle);
			if (playedSamples < 0)  {
				#if debug
				trace("playedSamples should positive : bug in driver");
				#end
				playedSamples = 0;
			}
			c.position = s.start / targetRate + playedSamples / s.buffers[0].sampleRate;
			c.positionChanged = false;

			// was a Pan added or removed? rebind at the synced position, switching between the mixed and the plain buffers
			if (s.panned != usesPan(c)) {
				releaseSource(s);
				continue;
			}

			// enqueue next buffers
			while (s.buffers.length < (s.panned ? PAN_BUFFER_QUEUE_LENGTH : BUFFER_QUEUE_LENGTH)) {
				var queued = s.buffers.length;
				var b = s.buffers[s.buffers.length - 1];
				if (!b.isEnd) {
					// next stream buffer
					queueBuffer(s, b.sound, b.start + b.samples);
				} else if (c.queue.length > 0) {
					// queue next sound buffer
					var snd = c.queue[0];
					if( queueBuffer(s, snd, 0) ) {
						c.queue.shift();
						s.nextSounds.push(snd);
					}
				} else if (c.loop) {
					// requeue last played sound
					if( queueBuffer(s, b.sound, 0) )
						s.nextSounds.push(null);
				}
				// one buffer per update, as many as needed for mixed ones
				if (!s.panned || s.buffers.length == queued) break;
			}
		}

		// --------------------------------------------------------------------
		// calc audible volume & virtualize inaudible channels
		// --------------------------------------------------------------------

		var c = channels;
		while (c != null) {
			c.calcAudibleVolume(now);
			if( c.isLoading && !c.sound.getData().isLoading() )
				c.isLoading = false;
			c.isVirtual = suspended || c.pause || c.mute || c.channelGroup.mute || (c.allowVirtual && c.audibleVolume < VIRTUAL_VOLUME_THRESHOLD) || c.isLoading;
			c = c.next;
		}

		// --------------------------------------------------------------------
		// sort channels by priority
		// --------------------------------------------------------------------

		channels = haxe.ds.ListSort.sortSingleLinked(channels, sortChannel);

		// --------------------------------------------------------------------
		// virtualize sounds that puts the put the audible count over the maximum number of sources
		// --------------------------------------------------------------------

		var audibleCount = 0;
		var c = channels;
		while (c != null && !c.isVirtual) {
			if (++audibleCount > sources.length) c.isVirtual = true;
			else if (c.soundGroup.maxAudible >= 0) {
				if(c.soundGroup.lastUpdate != now) {
					c.soundGroup.lastUpdate = now;
					c.soundGroup.numAudible = 0;
				}
				if (++c.soundGroup.numAudible > c.soundGroup.maxAudible) {
					c.isVirtual = true;
					--audibleCount;
				}
			}
			c = c.next;
		}

		// --------------------------------------------------------------------
		// free sources that points to virtualized channels
		// --------------------------------------------------------------------

		for (s in sources) {
			if (s.channel == null || !s.channel.isVirtual) continue;
			releaseSource(s);
		}

		// --------------------------------------------------------------------
		// bind non-virtual channels to sources
		// --------------------------------------------------------------------

		var c = channels;
		while (c != null) {
			if (c.source != null || c.isVirtual) {
				c = c.next;
				continue;
			}

			// look for a free source
			var s = null;
			for (s2 in sources) if( s2.channel == null ) {
				s = s2;
				break;
			}

			if (s == null) throw "could not get a source";
			s.channel = c;
			c.source = s;
			s.panned = usesPan(c);
			s.panValue = Math.NaN;

			checkTargetFormat(c.sound.getData(), c.soundGroup.mono);
			s.start = Math.floor(c.position * targetRate);
			if( s.start < 0 ) s.start = 0;
			queueBuffer(s, c.sound, s.start);
			c.positionChanged = false;
			c = c.next;
		}

		// --------------------------------------------------------------------
		// update source parameters
		// --------------------------------------------------------------------

		var usedEffects : Effect = null;
		var volume = hasMasterVolume ? 1. : masterVolume;
		for (s in sources) {
			var c = s.channel;
			if (c == null) continue;

			var v = c.currentVolume * volume;
			if (s.volume != v) {
				if (v < 0) v = 0;
				s.volume = v;
				driver.setSourceVolume(s.handle, v);
				#if hlopenal
				if( v > 1 ) Sys.println("Could not set volume " + v + " on " + c.sound);
				#end
			}

			if (!s.playing) {
				driver.playSource(s.handle);
				s.playing = true;
			}

			// unbind removed effects
			var i = c.bindedEffects.length;
			while (--i >= 0) {
				var e = c.bindedEffects[i];
				if (c.effects.indexOf(e) < 0 && c.channelGroup.effects.indexOf(e) < 0)
					unbindEffect(c, s, e);
			}

			// bind added effects
			for (e in c.channelGroup.effects) if (c.bindedEffects.indexOf(e) < 0) bindEffect(c, s, e);
			for (e in c.effects) if (c.bindedEffects.indexOf(e) < 0) bindEffect(c, s, e);

			// register used effects
			for (e in c.bindedEffects) usedEffects = regEffect(usedEffects, e);
		}

		// --------------------------------------------------------------------
		// update effects
		// --------------------------------------------------------------------

		usedEffects = haxe.ds.ListSort.sortSingleLinked(usedEffects, sortEffect);
		var e = usedEffects;
		while (e != null) {
			e.driver.update(e);
			e = e.next;
		}

		for (s in sources) {
			var c = s.channel;
			if (c == null) continue;
			for (e in c.bindedEffects) e.driver.apply(e, s.handle);
		}

		for (e in effectGC) if (now - e.lastStamp > e.retainTime) {
			e.driver.release();
			effectGC.remove(e);
			break;
		}

		// --------------------------------------------------------------------
		// update virtual channels
		// --------------------------------------------------------------------

		updateVirtualChannels(now);

		// --------------------------------------------------------------------
		// update global driver parameters
		// --------------------------------------------------------------------

		listener.direction.normalize();
		listener.up.normalize();

		if( hasMasterVolume ) driver.setMasterVolume(masterVolume);
		driver.setListenerParams(listener.position, listener.direction, listener.up, listener.velocity);

		driver.update();

		// --------------------------------------------------------------------
		// sound buffer cache GC
		// --------------------------------------------------------------------

		if (soundBufferCount >= SOUND_BUFFER_CACHE_SIZE) {
			var now = haxe.Timer.stamp();
			var i = 0;
			while (i < soundBufferKeys.length) {
				var k = soundBufferKeys[i];
				var b = soundBufferMap.get(k);
				i++;
				if (b.refs > 0 || b.lastStop + 60.0 > now) continue;
				soundBufferMap.remove(k);
				soundBufferKeys.remove(k);
				i--;
				b.dispose();
				--soundBufferCount;
			}
		}
	}

	// ------------------------------------------------------------------------
	// internals
	// ------------------------------------------------------------------------

	function progressiveDecodeBuffer( s : Source, snd : hxd.res.Sound, start : Int ) {
		var data = snd.getData();
		var samples = Math.ceil(STREAM_BUFFER_SAMPLE_COUNT / BUFFER_STREAM_SPLIT);
		if( s.streamStart != start || s.streamSound != snd ) {
			s.streamSound = snd;
			s.streamStart = start;
			s.streamPos = start;
		}
		var end = start + STREAM_BUFFER_SAMPLE_COUNT;
		if( s.streamPos == end )
			return true; // already done
		var bpp = data.getBytesPerSample();
		var reqSize = STREAM_BUFFER_SAMPLE_COUNT * bpp;
		if( s.streamBuffer == null || s.streamBuffer.length < reqSize ) {
			s.streamBuffer = haxe.io.Bytes.alloc(reqSize);
			s.streamPos = start;
		}
		var remain = end - s.streamPos;
		if( remain > samples ) remain = samples;
		data.decode(s.streamBuffer, (s.streamPos - start) * bpp, s.streamPos, remain);
		s.streamPos += remain;
		return s.streamPos == end;
	}

	function queueBuffer(s : Source, snd : hxd.res.Sound, start : Int) {
		var data   = snd.getData();
		var sgroup = s.channel.soundGroup;

		var b : Buffer = null;
		if (!s.panned && data.duration <= STREAM_DURATION) {
			// queue sound buffer
			b = getSoundBuffer(snd, sgroup);
			driver.queueBuffer(s.handle, b.handle, start, true);
		} else {

			// wait until fully decoded
			if( !s.panned && s.buffers.length > 0 && BUFFER_STREAM_SPLIT > 1 && !progressiveDecodeBuffer(s, snd, start) )
				return false;

			// queue stream buffer
			b = getStreamBuffer(s, snd, sgroup, start);
			driver.queueBuffer(s.handle, b.handle, 0, b.isEnd);
		}
		s.buffers.push(b);
		return true;
	}

	function unqueueBuffer(s : Source) {
		var b = s.buffers.shift();
		if( b == null ) return null; // some drivers (xbo) might wrongly report ended buffer after source stop, let's ignore
		driver.unqueueBuffer(s.handle, b.handle);
		if (b.isStream) freeStreamBuffers.unshift(b);
		else if (--b.refs == 0) b.lastStop = haxe.Timer.stamp();
		return b;
	}

	static function regEffect(list : Effect, e : Effect) : Effect {
		var l = list;
		while (l != null) {
			if (l == e) return list;
			l = l.next;
		}
		e.next = list;
		return e;
	}

	function bindEffect(c : Channel, s : Source, e : Effect) {
		if (e.refs == 0 && !effectGC.remove(e)) e.driver.acquire();
		++e.refs;
		e.driver.bind(e, s.handle);
		c.bindedEffects.push(e);
	}

	function unbindEffect(c : Channel, s : Source, e : Effect) {
		e.driver.unbind(e, s.handle);
		c.bindedEffects.remove(e);
		if (--e.refs == 0) {
			e.lastStamp = now;
			effectGC.push(e);
		}
	}

	function releaseSource(s : Source) {
		if (s.channel != null) {
			// give the channel back the queued sounds the source took but did not reach
			var i = s.nextSounds.length;
			while (i-- > 0)
				if (s.nextSounds[i] != null) s.channel.queue.unshift(s.nextSounds[i]);
			for (e in s.channel.bindedEffects.copy()) unbindEffect(s.channel, s, e);
			s.channel.bindedEffects = [];
			s.channel.source = null;
			s.channel = null;
		}

		if (s.playing) {
			s.playing = false;
			driver.stopSource(s.handle);
			s.volume = -1.0;
		}

		while(s.buffers.length > 0) unqueueBuffer(s);
		s.nextSounds = [];
	}

	var targetRate     : Int;
	var targetFormat   : Data.SampleFormat;
	var targetChannels : Int;

	function checkTargetFormat(dat : hxd.snd.Data, forceMono = false) {

		targetRate = dat.samplingRate;
		#if (!usesys && !hlopenal && (!js || useal))
		// perform resampling to nativechannel frequency
		targetRate = hxd.snd.openal.Emulator.NATIVE_FREQ;
		#end
		targetChannels = forceMono || dat.channels == 1 ? 1 : 2;
		targetFormat   = switch (dat.sampleFormat) {
			case UI8 : UI8;
			case I16 : I16;
			#if js
			case F32 : F32;
			#else
			case F32 : I16;
			#end
		}
		return targetChannels == dat.channels && targetFormat == dat.sampleFormat && targetRate == dat.samplingRate;
	}

	function getSoundBuffer(snd : hxd.res.Sound, grp : SoundGroup) : Buffer {
		var data = snd.getData();
		var mono = grp.mono;
		var key  = snd.entry.path;

		if (mono && data.channels != 1) key += "mono";
		var b = soundBufferMap.get(key);
		if (b == null) {
			b = new Buffer(driver);
			b.isStream = false;
			b.isEnd = true;
			b.sound = snd;
			data.load(function() fillSoundBuffer(b, data, mono));
			soundBufferMap.set(key, b);
			soundBufferKeys.push(key);
			++soundBufferCount;
		}

		++b.refs;
		return b;
	}

	function fillSoundBuffer(buf : Buffer, dat : hxd.snd.Data, forceMono = false) {
		if (!checkTargetFormat(dat, forceMono))
			dat = dat.resample(targetRate, targetFormat, targetChannels);

		var length = dat.samples * dat.getBytesPerSample();
		var bytes  = getTmpBytes(length);
		dat.decode(bytes, 0, 0, dat.samples);
		driver.setBufferData(buf.handle, bytes, length, targetFormat, targetChannels, targetRate);
		buf.sampleRate = targetRate;
		buf.samples    = dat.samples;
	}

	function getStreamBuffer( src : Source, snd : hxd.res.Sound, grp : SoundGroup, start : Int) : Buffer {
		var data = snd.getData();

		var b = freeStreamBuffers.shift();
		if (b == null) {
			b = new Buffer(driver);
			b.isStream = true;
		}

		var samples = src.panned ? PAN_BUFFER_SAMPLE_COUNT : STREAM_BUFFER_SAMPLE_COUNT;
		if (start + samples >= data.samples) {
			samples = data.samples - start;
			b.isEnd = true;
		} else {
			b.isEnd = false;
		}

		b.sound   = snd;
		b.samples = samples;
		b.start   = start;

		var size  = samples * data.getBytesPerSample();
		var bytes;
		if( !src.panned && src.streamSound == snd && src.streamStart == start ) {
			// finish progressive decoding and use progressive buffer
			while( !progressiveDecodeBuffer(src, snd, start) ) {};
			bytes = src.streamBuffer;
		} else {
			bytes = getTmpBytes(size);
			data.decode(bytes, 0, start, samples);
		}

		if (!checkTargetFormat(data, grp.mono)) {
			size = Math.ceil(samples * (targetRate / data.samplingRate)) * targetChannels * Data.formatBytes(targetFormat);
			var resampleBytes = getResampleBytes(size);
			data.resampleBuffer(resampleBytes, 0, bytes, 0, targetRate, targetFormat, targetChannels, samples);
			bytes = resampleBytes;
		}

		var channels = targetChannels, format = targetFormat;
		if (src.panned) {
			var pan = getPan(src.channel);
			var frames = Std.int(size / (targetChannels * Data.formatBytes(targetFormat)));
			format = PAN_FLOAT ? Data.SampleFormat.F32 : targetFormat;
			size = frames * 2 * Data.formatBytes(format);
			if (panBytes == null || panBytes.length < size) panBytes = haxe.io.Bytes.alloc(size);
			Pan.mix(bytes, targetFormat, targetChannels, frames, Math.isNaN(src.panValue) ? pan.value : src.panValue, pan.value, panBytes, format);
			src.panValue = pan.value;
			bytes = panBytes;
			channels = 2;
		}

		driver.setBufferData(b.handle, bytes, size, format, channels, targetRate);
		b.sampleRate = targetRate;
		return b;
	}

	static function getPan(c : Channel) : Pan {
		for (e in c.effects) { var p = Std.downcast(e, Pan); if (p != null) return p; }
		for (e in c.channelGroup.effects) { var p = Std.downcast(e, Pan); if (p != null) return p; }
		return null;
	}

	static inline function usesPan(c : Channel) {
		return !NATIVE_PAN && getPan(c) != null;
	}

	function sortChannel(a : Channel, b : Channel) {
		if (a.isVirtual != b.isVirtual)
			return a.isVirtual ? 1 : -1;

		if (a.channelGroup.priority != b.channelGroup.priority)
			return a.channelGroup.priority < b.channelGroup.priority ? 1 : -1;

		if (a.priority != b.priority)
			return a.priority < b.priority ? 1 : -1;

		if (a.audibleVolume != b.audibleVolume)
			return a.audibleVolume < b.audibleVolume ? 1 : -1;

		return a.id < b.id ? 1 : -1;
	}

	function sortEffect(a : Effect, b : Effect) {
		return b.priority - a.priority;
	}

	function releaseChannel(c : Channel) {

		// was already released
		if( c.manager == null )
			return;

		if (channels == c) {
			channels = c.next;
		} else {
			var prev = channels;
			while (prev.next != c)
				prev = prev.next;
			prev.next = c.next;
		}

		for (e in c.effects) c.removeEffect(e);
		if (c.source != null) releaseSource(c.source);
		c.next = null;
		c.manager = null;
		c.effects = null;
		c.bindedEffects = null;
		c.currentFade = null;
		@:privateAccess {
			var snd = c.sound;
			if( snd != null && snd.channel == c ) snd.channel = null;
		}
	}
}
