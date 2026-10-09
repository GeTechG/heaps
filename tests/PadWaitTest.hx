// Run: haxe -cp . -cp tests -lib format --main PadWaitTest --js test.js && node test.js
// hxd.Pad.wait on JS must report the gamepads the page already sees, each of them once.
class PadWaitTest {

	static function gamepad( index : Int ) : Dynamic {
		return { index : index, id : "pad" + index, connected : true, buttons : [], axes : [] };
	}

	static function main() {
		var listeners = new Map<String, Dynamic -> Void>();
		var win : Dynamic = {
			location : { protocol : "http:" },
			addEventListener : function( name : String, f : Dynamic -> Void ) listeners.set(name, f),
			requestAnimationFrame : function( f : Dynamic ) return 0,
		};
		var nav : Dynamic = { getGamepads : function() : Array<Dynamic> return [null, gamepad(1)] };
		var g : Dynamic = js.Lib.global;
		g.window = win;
		// node defines a read-only global navigator
		js.lib.Object.defineProperty(g, "navigator", { value : nav, configurable : true });

		var seen = [];
		hxd.Pad.wait(function(p) seen.push(p.index));
		if( seen.join(",") != "1" ) throw "already connected pad not reported: [" + seen.join(",") + "]";

		listeners.get("gamepadconnected")({ gamepad : gamepad(1) });
		if( seen.join(",") != "1" ) throw "pad reported twice: [" + seen.join(",") + "]";

		listeners.get("gamepadconnected")({ gamepad : gamepad(0) });
		if( seen.join(",") != "1,0" ) throw "newly connected pad not reported: [" + seen.join(",") + "]";

		listeners.get("gamepaddisconnected")({ gamepad : gamepad(1) });
		listeners.get("gamepadconnected")({ gamepad : gamepad(1) });
		if( seen.join(",") != "1,0,1" ) throw "reconnected pad not reported: [" + seen.join(",") + "]";

		trace("PadWaitTest OK");
		js.Syntax.code("process.exit(0)");
	}

}
