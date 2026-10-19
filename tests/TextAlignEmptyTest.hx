// Run: haxe -cp . -cp tests -lib format --main TextAlignEmptyTest --js test.js && node test.js
// h2d.Text with a centred or right alignment must give a finite width when splitRawText measures no line.
@:access(h2d.Font)
class TextAlignEmptyTest {

	static function main() {
		var font = new h2d.Font("test", 10);
		for( c in 'a'.code...'z'.code + 1 )
			font.glyphs.set(c, new h2d.Font.FontChar(null, -6)); // negative advance: no line is ever flushed
		font.glyphs.set('R'.code, new h2d.Font.FontChar(null, -6));
		var t = new h2d.Text(font);
		for( align in ([Center, Right, MultilineCenter, MultilineRight] : Array<h2d.Text.Align>) ) {
			t.textAlign = align;
			t.text = "Resume";
			if( !Math.isFinite(t.textWidth) ) throw 'textWidth is ${t.textWidth} for $align';
		}
		trace("TextAlignEmptyTest OK");
		#if js js.Syntax.code("process.exit(0)"); #end // heaps keeps node alive
	}
}
