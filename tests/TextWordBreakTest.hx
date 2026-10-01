// Run (needs a UTF-16 target, eval strings are not): haxe -cp . -cp tests -lib format --main TextWordBreakTest --js test.js && node test.js
// h2d.Text.splitRawText with wordBreak must never split a UTF-16 surrogate pair.
@:access(h2d.Font)
class TextWordBreakTest {

	static inline function isHigh( c : Int ) return c >= 0xD800 && c <= 0xDBFF;
	static inline function isLow( c : Int ) return c >= 0xDC00 && c <= 0xDFFF;

	static function main() {
		var emoji = String.fromCharCode(0xD83D) + String.fromCharCode(0xDE00); // U+1F600
		var font = new h2d.Font("test", 10);
		var chars = [for( c in 'a'.code...'z'.code + 1 ) c];
		chars.push(' '.code);
		chars.push(0x1F600);
		for( c in chars )
			font.glyphs.set(c, new h2d.Font.FontChar(null, 10));
		var t = new h2d.Text(font);
		t.wordBreak = true;
		var texts = [emoji, emoji + emoji + emoji, "ab" + emoji + "cd" + emoji + emoji + "e", emoji + "abc", "abc" + emoji, "a " + emoji + emoji + " b"];
		// 5: narrower than any glyph (a pair alone at line start must not loop forever)
		for( maxWidth in [5, 10, 15, 25, 35] ) {
			t.maxWidth = maxWidth;
			for( text in texts ) {
				var lines = @:privateAccess t.splitRawText(text).split("\n");
				if( lines.join("") != text ) throw 'text lost at maxWidth=$maxWidth: ${haxe.Json.stringify(lines)}';
				for( l in lines ) {
					if( l.length == 0 ) throw 'empty line at maxWidth=$maxWidth';
					if( isLow(l.charCodeAt(0)) ) throw 'line starts with a low surrogate at maxWidth=$maxWidth';
					if( isHigh(l.charCodeAt(l.length - 1)) ) throw 'line ends with a high surrogate at maxWidth=$maxWidth';
				}
			}
		}
		trace("TextWordBreakTest OK");
		#if js js.Syntax.code("process.exit(0)"); #end // heaps keeps node alive
	}
}
