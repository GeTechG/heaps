// Run: haxe -cp . -cp tests -lib format --main TextJustifyTest --js test.js && node test.js
// h2d.Text with Align.Justify stretches the lines the word wrap broke to maxWidth and leaves the others as Left.
@:access(h2d)
class TextJustifyTest {

	static var font : h2d.Font;

	static function check( cond : Bool, msg : String ) {
		if( !cond ) throw msg;
	}

	// the x of every glyph laid out (one per char, \n aside), and the width
	static function layout( text : String, align : h2d.Text.Align, maxWidth : Null<Float>, letterSpacing = 0. ) {
		var t = new h2d.Text(font);
		t.letterSpacing = letterSpacing;
		t.wordBreak = true;
		t.maxWidth = maxWidth;
		t.textAlign = align;
		t.text = text;
		t.initGlyphs(t.text);
		var tmp = t.glyphs.content.tmp;
		var xs = [for( i in 0...Std.int(tmp.length / 32) ) tmp[i * 32]];
		return { xs : xs, width : t.textWidth, calc : t.calcTextWidth(text), lines : t.splitRawText(text).split("\n").length };
	}

	static function same( text : String, maxWidth : Null<Float>, what : String ) {
		var l = layout(text, Left, maxWidth), j = layout(text, Justify, maxWidth);
		check(j.xs.join(",") == l.xs.join(","), '$what: Justify ${j.xs} != Left ${l.xs}');
		check(j.width == l.width, '$what: width ${j.width} != ${l.width}');
	}

	// "aa aa aa aa" wraps after "aa aa ": the last 'a' of line 1 (glyph 4) ends at maxWidth, line 2 (glyphs 6...) is as Left
	static function twoLines( maxWidth : Float, letterSpacing : Float, what : String ) {
		var text = "aa aa aa aa";
		var l = layout(text, Left, maxWidth, letterSpacing), j = layout(text, Justify, maxWidth, letterSpacing);
		check(l.lines == 2, '$what: ${l.lines} lines');
		check(Math.abs(j.xs[4] + 10 - maxWidth) <= 1, '$what: line 1 ends at ${j.xs[4] + 10}, not $maxWidth');
		check(j.xs[3] > l.xs[3], '$what: line 1 not stretched');
		check(j.xs.slice(0, 2).join(",") == l.xs.slice(0, 2).join(","), '$what: first word moved');
		check(j.xs.slice(6).join(",") == l.xs.slice(6).join(","), '$what: last line ${j.xs.slice(6)} != Left ${l.xs.slice(6)}');
		check(Math.abs(j.width - maxWidth) <= 1, '$what: textWidth ${j.width}, not $maxWidth');
		check(j.calc == j.width, '$what: calcTextWidth ${j.calc} != textWidth ${j.width}');
	}

	static function main() {
		font = new h2d.Font("test", 10);
		for( c in 'a'.code...'z'.code + 1 )
			font.glyphs.set(c, new h2d.Font.FontChar(new h2d.Tile(null, 0, 0, 10, 10), 10));
		font.glyphs.set(' '.code, new h2d.Font.FontChar(new h2d.Tile(null, 0, 0, 5, 10), 5));

		twoLines(58, 0, "plain");
		same("aaaaaaaa", 35, "no spaces"); // wordBreak: "aaa" "aaa" "aa"
		same("aa aa\naa aa", 100, "forced break");
		same("aa aa aa aa", null, "no maxWidth");

		// kerning and letterSpacing: "aa aa " is 54 wide, the next 'a' passes 60
		font.glyphs.get('a'.code).addKerning('a'.code, -3);
		twoLines(60, 2, "kerning and letterSpacing");

		trace("TextJustifyTest OK");
		#if js js.Syntax.code("process.exit(0)"); #end // heaps keeps node alive
	}
}
