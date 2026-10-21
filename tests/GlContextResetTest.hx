// Run (HashLink/SDL, needs a display and an fmt.hdll built with Opus, as OpusDataTest): haxe -cp . -cp tests -lib format -lib hlsdl --main GlContextResetTest -hl test.hl && hl test.hl
// h3d.impl.GlDriver.onContextReset runs the engine's context-lost path: Engine.onContextLost, textures with realloc refilled, frames drawn without a GL error.
class GlContextResetTest extends hxd.App {

	var frame = 0;
	var lost = 0;
	var reallocs = 0;
	var tex : h3d.mat.Texture;

	static function fail( msg : String ) {
		Sys.println("FAIL: " + msg);
		Sys.exit(1);
	}

	static function checkGL( what : String ) {
		var err = sdl.GL.getError();
		if( err != 0 ) fail('$what: GL error 0x${StringTools.hex(err)}');
	}

	function red( t : h3d.mat.Texture ) {
		return t.capturePixels().getPixel(0, 0) & 0xFFFFFF == 0xFF0000;
	}

	override function init() {
		engine.onContextLost = () -> lost++;
		tex = new h3d.mat.Texture(16, 16);
		tex.realloc = () -> {
			reallocs++;
			tex.clear(0xFF0000);
		};
		tex.clear(0xFF0000);
		new h2d.Bitmap(h2d.Tile.fromTexture(tex), s2d);
	}

	override function update( dt : Float ) {
		frame++;
		switch( frame ) {
		case 3:
			checkGL("before the reset");
			var driver = Std.downcast(engine.driver, h3d.impl.GlDriver);
			if( driver == null ) fail("not a GlDriver");
			driver.onContextReset();
			if( lost != 1 ) fail('Engine.onContextLost called $lost times');
			if( @:privateAccess tex.t != null ) fail("texture not disposed by the reset");
		case 6:
			// drawn on the frames since the reset: the texture was reallocated and refilled
			if( reallocs != 1 ) fail('realloc called $reallocs times');
			var rt = new h3d.mat.Texture(16, 16, [Target]);
			s2d.drawTo(rt);
			if( !red(rt) ) fail("the bitmap does not draw red after the reset");
			checkGL("after the reset");
			Sys.println("ok");
			Sys.exit(0);
		default:
		}
	}

	static function main() {
		new GlContextResetTest();
	}
}
