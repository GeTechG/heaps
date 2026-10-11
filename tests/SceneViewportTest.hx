// Run: haxe -cp . -cp tests -lib format --main SceneViewportTest --js test.js && node test.js
// h2d.Scene.checkResize must give pointer conversion (offsetX/Y) the placement the scene is drawn with (viewportX/Y).
@:access(h2d.Scene)
@:access(h3d.Engine)
class SceneViewportTest {

	static function main() {
		// checkResize only reads the size of the current engine: no window, no driver
		var engine : h3d.Engine = Type.createEmptyInstance(h3d.Engine);
		h3d.Engine.CURRENT = engine;
		var scene : h2d.Scene = Type.createEmptyInstance(h2d.Scene);
		var aligns : Array<h2d.Scene.ScaleModeAlign> = [null, Left, Right, Center, Top, Bottom];
		var count = 0;
		function check( mode : h2d.Scene.ScaleMode ) {
			scene.scaleMode = mode;
			var drawnX = (scene.viewportX + 1) * engine.width / 2;
			var drawnY = (scene.viewportY + 1) * engine.height / 2;
			if( Math.abs(drawnX - scene.offsetX) > 1e-6 || Math.abs(drawnY - scene.offsetY) > 1e-6 )
				throw '$mode in ${engine.width}x${engine.height}: drawn at $drawnX,$drawnY but offset is ${scene.offsetX},${scene.offsetY}';
			count++;
		}
		for( w in 1900...1960 ) for( h in [1080, 1087, 1091, 1107] ) {
			engine.width = w;
			engine.height = h;
			for( ha in aligns ) for( va in aligns ) {
				for( zoom in [1, 2, 3, 6, 1.5] )
					check(Fixed(320, 180, zoom, ha, va));
				check(LetterBox(320, 180, false, ha, va));
				check(LetterBox(320, 180, true, ha, va));
			}
		}

		// the example of the report: an 11 px margin is less than two scene pixels, so nothing is left above
		engine.width = 1920;
		engine.height = 1091;
		scene.scaleMode = Fixed(320, 180, 6);
		if( scene.offsetY != 0 ) throw 'offsetY=${scene.offsetY}, expected 0';
		engine.height = 1107;
		scene.checkResize();
		if( scene.offsetY != 12 ) throw 'offsetY=${scene.offsetY}, expected 12';
		trace('ok ($count placements)');
	}

}
