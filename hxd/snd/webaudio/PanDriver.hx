package hxd.snd.webaudio;

#if (js && !useal)
import js.html.audio.StereoPannerNode;
import js.html.audio.AudioContext;
import hxd.snd.effect.Pan;
import hxd.snd.Driver.EffectDriver;
import hxd.snd.webaudio.AudioTypes;

class PanDriver extends EffectDriver<Pan> {

	var pool : Array<StereoPannerNode>;

	public function new() {
		pool = [];
		super();
	}

	function get( ctx : AudioContext ) {
		if ( pool.length != 0 ) {
			return pool.pop();
		}
		return ctx.createStereoPanner();
	}

	override public function bind(e : Pan, source : SourceHandle) : Void {
		source.stereoPanner = get(source.driver.ctx);
		apply(e, source);
		source.updateDestination();
	}

	override function apply(e : Pan, source : SourceHandle) : Void {
		source.stereoPanner.pan.value = e.value < -1 ? -1 : e.value > 1 ? 1 : e.value;
	}

	override function unbind(e : Pan, source : SourceHandle) : Void {
		pool.push(source.stereoPanner);
		source.stereoPanner.disconnect();
		source.stereoPanner = null;
		if ( source.driver != null )
			source.updateDestination();
	}
}
#end
