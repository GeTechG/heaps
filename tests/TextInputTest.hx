// Run: haxe -cp . -cp tests --main TextInputTest --interp
// Run (HashLink/SDL, needs a display; with the GeTechG/hashlink SDL library in place of -lib hlsdl it checks the IME path): haxe -cp . -cp tests -lib format -lib hlsdl --main TextInputTest -hl test.hl && hl test.hl
// hxd.Window sends one ETextInput per code point of a commit and reports the IME composition through onTextEditing, until stopTextInput and again after startTextInput.
class TextInputTest {

	static var failures = 0;

	static function check( name : String, ok : Bool ) {
		if( !ok ) failures++;
		Sys.println((ok ? "ok   " : "FAIL ") + name);
	}

	static function codes( events : Array<hxd.Event> ) {
		return [for( e in events ) e.kind == ETextInput ? e.charCode : -1].join(",");
	}

	static function main() {
		var events = @:privateAccess hxd.Event.textInputs("日本語", 3, 4);
		check("a commit of three characters gives three ETextInput in order", codes(events) == "26085,26412,35486");
		check("the events carry the position", events[0].relX == 3 && events[0].relY == 4);
		check("a character outside the BMP is one ETextInput", codes(@:privateAccess hxd.Event.textInputs("a😀", 0, 0)) == "97,128512");
		check("an empty commit gives no event", codes(@:privateAccess hxd.Event.textInputs("", 0, 0)) == "");
		#if hlsdl
		sdlWindow();
		#end
		if( failures > 0 ) {
			Sys.println(failures + " check(s) failed");
			Sys.exit(1);
		}
		Sys.println("all checks passed");
	}

	#if hlsdl
	static function utf8( s : String ) : hl.Bytes {
		return @:privateAccess s.toUtf8();
	}

	// an sdl.Event as the SDL library fills it: the first four bytes in keyCode, the whole text in `text` when the library has it
	static function sdlEvent( type : Int, s : String, hasText : Bool ) {
		var e = new sdl.Event();
		e.type = cast type;
		var b = haxe.io.Bytes.ofString(s);
		e.keyCode = 0;
		for( i in 0...(b.length < 4 ? b.length : 4) )
			e.keyCode |= b.get(i) << (i * 8);
		if( hasText ) @:privateAccess hxd.Event.ifHasField("sdl.Event", "text", e.text = utf8(s), {});
		return e;
	}

	static function sdlWindow() {
		sdl.Sdl.init();
		var hasText = @:privateAccess hxd.Event.ifHasField("sdl.Event", "text", true, false);
		Sys.println("SDL library " + (hasText ? "with" : "without") + " sdl.Event.text");
		var w = new hxd.Window("TextInputTest", 64, 64, { hidden: true });
		var got = [];
		w.addEventTarget(e -> got.push(e));

		@:privateAccess w.onEvent(sdlEvent(9, "日本語", hasText));
		check("an SDL commit gives " + (hasText ? "one ETextInput per character" : "its first character"), codes(got) == (hasText ? "26085,26412,35486" : "26085"));

		got = [];
		@:privateAccess w.onEvent(sdlEvent(9, "é", hasText));
		check("a one-character SDL commit gives one ETextInput", codes(got) == "233");

		if( hasText ) {
			var editing = [];
			w.onTextEditing = (text, cursor, length) -> editing.push(text + "/" + cursor + "/" + length);
			var e = sdlEvent(10, "にほ", true);
			e.value = 2;
			e.reference = 0;
			got = [];
			@:privateAccess w.onEvent(e);
			e = sdlEvent(10, "", true);
			e.value = 0;
			e.reference = 0;
			@:privateAccess w.onEvent(e);
			check("SDL TextEditing calls onTextEditing with the composition, then empty", editing.join(" ") == "にほ/2/0 /0/0");
			check("SDL TextEditing sends no event", got.length == 0);
		}

		w.setTextInputArea(10, 20, 200, 24, 5);
		check("setTextInputArea returns", true);

		sdlStopStart(w, hasText);
	}

	static function sdlKey( type : Int, keyCode : Int ) {
		var e = new sdl.Event();
		e.type = cast type;
		e.keyCode = keyCode;
		return e;
	}

	static function sdlEditing( text : String, cursor : Int ) {
		var e = sdlEvent(10, text, true);
		e.value = cursor;
		e.reference = 0;
		return e;
	}

	static function sdlStopStart( w : hxd.Window, hasText : Bool ) {
		var got = [];
		w.addEventTarget(e -> got.push(e));
		var editing = [];
		w.onTextEditing = (text, cursor, length) -> editing.push(text + "/" + cursor + "/" + length);
		var commit = hasText ? "26085,26412,35486" : "26085";
		@:privateAccess hxd.Window.initChars(); // hxd.System does it at startup

		w.stopTextInput();
		check("stopTextInput without a composition does not call onTextEditing", editing.length == 0);
		@:privateAccess w.onEvent(sdlEvent(9, "日本語", hasText));
		check("a TextInput SDL had queued gives no ETextInput while stopped", got.length == 0);
		@:privateAccess w.onEvent(sdlKey(7, "a".code));
		@:privateAccess w.onEvent(sdlKey(8, "a".code));
		check("key events keep coming while stopped", got.length == 2 && got[0].kind == EKeyDown && got[1].kind == EKeyUp && got[0].keyCode == hxd.Key.A && got[1].keyCode == hxd.Key.A);

		got = [];
		w.startTextInput();
		@:privateAccess w.onEvent(sdlEvent(9, "日本語", hasText));
		check("startTextInput restores ETextInput", codes(got) == commit);

		if( hasText ) {
			w.stopTextInput();
			@:privateAccess w.onEvent(sdlEditing("にほ", 2));
			@:privateAccess w.onEvent(sdlEditing("", 0));
			check("a TextEditing SDL had queued does not call onTextEditing while stopped", editing.length == 0);
			w.startTextInput();
			@:privateAccess w.onEvent(sdlEditing("にほ", 2));
			check("startTextInput restores onTextEditing", editing.join(" ") == "にほ/2/0");

			editing = [];
			w.stopTextInput();
			check("a composition cut short ends with an empty onTextEditing", editing.join(" ") == "/0/0");
			w.stopTextInput();
			check("a second stopTextInput does not end it again", editing.length == 1);
			w.startTextInput();
			@:privateAccess w.onEvent(sdlEditing("", 0));

			editing = [];
			@:privateAccess w.onEvent(sdlEditing("にほ", 2));
			@:privateAccess w.onEvent(sdlEditing("", 0));
			w.stopTextInput();
			check("stopTextInput after a composition ended does not end it again", editing.join(" ") == "にほ/2/0 /0/0");
			w.startTextInput();
		}
	}
	#end

}
