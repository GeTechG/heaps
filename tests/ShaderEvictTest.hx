// Run (the second half on HashLink/SDL, needs a display): haxe -cp . -cp tests -lib format --main ShaderEvictTest --interp && haxe -cp . -cp tests -lib format -lib hlsdl -D evict_gl --main ShaderEvictTest -hl test.hl && hl test.hl
// hxsl.Cache.evict forgets what was linked from a SharedShader and releases the driver programs no cached shader shares; GlDriver deletes them and compiles them again when they come back.

class TintA extends hxsl.Shader {
	static var SRC = {
		var pixelColor : Vec4;
		function fragment() {
			pixelColor.r *= 0.5;
		}
	};
}

class TintB extends hxsl.Shader {
	static var SRC = {
		var pixelColor : Vec4;
		function fragment() {
			pixelColor.g *= 0.5;
		}
	};
}

class Fade extends hxsl.Shader {
	static var SRC = {
		var pixelColor : Vec4;
		function fragment() {
			pixelColor.a *= 0.5;
		}
	};
}

class RecordingDriver extends h3d.impl.Driver {
	public var disposed : Array<Int> = [];
	public function new() {}
	override function disposeShader( shader : hxsl.RuntimeShader ) {
		disposed.push(shader.id);
	}
}

#if evict_gl
class ShaderEvictTest extends hxd.App {

	var frame = 0;
	var bmp : h2d.Bitmap;
	var shA : hxsl.SharedShader;
	var dynA : hxsl.DynamicShader;
	var evicted : Array<hxsl.RuntimeShader>;

	static function main() {
		new ShaderEvictTest();
	}

	override function init() {
		bmp = new h2d.Bitmap(h2d.Tile.fromColor(0xFFFFFF, 64, 64), s2d);
		shA = new hxsl.SharedShader((TintA : Dynamic).SRC);
		dynA = new hxsl.DynamicShader(shA);
		bmp.addShader(dynA);
	}

	function programs() : Map<Int, Dynamic> {
		return cast @:privateAccess (cast engine.driver : h3d.impl.GlDriver).programs;
	}

	function check( cond : Bool, msg : String ) {
		if( !cond ) {
			Sys.println("FAIL: " + msg);
			Sys.exit(1);
		}
	}

	function glError() {
		return sdl.GL.getError();
	}

	override function update( dt : Float ) {
		frame++;
		switch( frame ) {
		case 3:
			check(glError() == 0, "GL error before eviction");
			bmp.removeShader(dynA);
			evicted = hxsl.Cache.get().evict(shA);
			check(evicted.length > 0, "nothing evicted");
			for( rt in evicted )
				check(!programs().exists(rt.id), "program of " + rt.id + " kept");
			bmp.addShader(new hxsl.DynamicShader(new hxsl.SharedShader((TintB : Dynamic).SRC)));
		case 6:
			check(glError() == 0, "GL error after a new text");
			var rt = evicted[0];
			engine.selectShader(rt);
			check(programs().exists(rt.id), "evicted shader not compiled again");
			check(glError() == 0, "GL error selecting an evicted shader");
		case 9:
			check(glError() == 0, "GL error drawing after reselection");
			Sys.println("ShaderEvictTest (GL): OK");
			Sys.exit(0);
		default:
		}
	}
}
#else
class ShaderEvictTest {

	static var failures = 0;
	static var cache : hxsl.Cache;
	static var globals : hxsl.Globals;
	static var output : hxsl.Shader;
	static var base : h3d.shader.Base2d;

	static function check( cond : Bool, msg : String ) {
		if( !cond ) {
			Sys.println("FAIL: " + msg);
			failures++;
		}
	}

	static function shared( cl : Class<hxsl.Shader> ) {
		return new hxsl.SharedShader((cl : Dynamic).SRC);
	}

	static function link( shaders : Array<hxsl.Shader> ) : hxsl.RuntimeShader {
		var list : hxsl.ShaderList = null;
		var all = [output, base].concat(shaders);
		var i = all.length;
		while( i-- > 0 )
			list = new hxsl.ShaderList(all[i], list);
		for( s in list.next )
			s.updateConstants(globals);
		return cache.link(list, Default);
	}

	static function reset() {
		cache = @:privateAccess new hxsl.Cache();
		output = cache.getLinkShader([Value("output.color")]);
	}

	static function sameSet( a : Array<hxsl.RuntimeShader>, b : Array<hxsl.RuntimeShader> ) {
		if( a.length != b.length ) return false;
		for( x in a ) if( b.indexOf(x) < 0 ) return false;
		return true;
	}

	static function main() {
		globals = new hxsl.Globals();
		base = new h3d.shader.Base2d();
		// Linked shaders are forgotten, other shaders stay cached, the program of an evicted text is released
		reset();
		var shA = shared(TintA);
		var dynA = new hxsl.DynamicShader(shA);
		var rtA = link([dynA]);
		var rtFadeA = link([new Fade(), dynA]);
		var rtBase = link([]);
		var rtFade = link([new Fade()]);
		var drv = new RecordingDriver();
		var removed = cache.evict(shA, drv);
		check(sameSet(removed, [rtA, rtFadeA]), "evict returns the shaders linked from shA, got " + removed.length);
		check(drv.disposed.length == 2 && drv.disposed.indexOf(rtA.id) >= 0 && drv.disposed.indexOf(rtFadeA.id) >= 0, "programs of shA released: " + drv.disposed);
		check(link([dynA]) != rtA, "linking an evicted list compiles a new shader");
		check(link([]) == rtBase, "a list without shA stays cached");
		check(link([new Fade()]) == rtFade, "another list without shA stays cached");

		// A shader never linked
		var drv = new RecordingDriver();
		var removed = cache.evict(shared(TintB), drv);
		check(removed.length == 0 && drv.disposed.length == 0, "evicting a shader never linked removes and releases nothing");

		// Same text in another SharedShader
		reset();
		var sh1 = shared(TintA), sh2 = shared(TintA);
		var dyn2 = new hxsl.DynamicShader(sh2);
		var r1 = link([new hxsl.DynamicShader(sh1)]);
		var r2 = link([dyn2]);
		check(r1 != r2 && r1.id == r2.id, "same text shares the id");
		var drv = new RecordingDriver();
		check(sameSet(cache.evict(sh1, drv), [r1]), "only the first text's shader is removed");
		check(drv.disposed.length == 0, "a program still shared is not released: " + drv.disposed);
		check(link([dyn2]) == r2 && r2.id == r1.id, "the second's shader stays with its id");

		// Same text compiled again after eviction
		var drv = new RecordingDriver();
		cache.evict(sh2, drv);
		check(drv.disposed.length == 1 && drv.disposed[0] == r1.id, "the last shader of an id releases it: " + drv.disposed);
		var r3 = link([new hxsl.DynamicShader(shared(TintA))]);
		check(r3.id != r1.id, "the same text after eviction gets a new id");
		var rB = link([new hxsl.DynamicShader(shared(TintB))]);
		check(rB.id != r3.id, "another text gets its own id");

		// Batch shaders made from an evicted shader follow it
		reset();
		var shA = shared(TintA);
		var dynA = new hxsl.DynamicShader(shA);
		var rtA = link([dynA]);
		var list = new hxsl.ShaderList(base, new hxsl.ShaderList(dynA));
		var batch = cache.makeBatchShader(rtA, list, null);
		check(@:privateAccess cache.batchShaders.exists(rtA), "batch shader cached");
		cache.evict(shA, new RecordingDriver());
		check(!@:privateAccess cache.batchShaders.exists(rtA), "batch shader of an evicted shader forgotten");

		// Without a driver and without an engine nothing is released and nothing fails
		reset();
		var shA = shared(TintA);
		link([new hxsl.DynamicShader(shA)]);
		check(cache.evict(shA).length == 1, "evict without a driver");

		if( failures > 0 ) {
			Sys.println(failures + " failure(s)");
			Sys.exit(1);
		}
		Sys.println("ShaderEvictTest: OK");
	}
}
#end
