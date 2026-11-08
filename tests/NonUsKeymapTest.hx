// Run (HashLink/SDL, needs a display): haxe -cp . -cp tests -lib format -lib hlsdl --main NonUsKeymapTest -hl test.hl && hl test.hl
// hxd.Window on HashLink/SDL gives a character key of a non-Latin layout the hxd.Key of its position, never a key SDL folds from a scancode.
import hxd.Key;

class NonUsKeymapTest {

	static var failures = 0;

	// SDL_SCANCODE_A, then B … Z in order
	static inline var SCANCODE_A = 4;
	static inline var SCANCODE_GRAVE = 53;
	static inline var SCANCODE_KP_ENTER = 88;
	// SDLK_SCANCODE_MASK: a keycode SDL derives from a scancode
	static inline var SCANCODE_MASK = 1 << 30;

	// the Russian (ЙЦУКЕН) letter on each key A … Z of a US keyboard
	static var RUSSIAN = "фисвуапршолдьтщзйкыегмцчня";

	static function check( name : String, ok : Bool ) {
		if( !ok ) failures++;
		Sys.println((ok ? "ok   " : "FAIL ") + name);
	}

	static function main() {
		sdl.Sdl.init();
		var w = new hxd.Window("NonUsKeymapTest", 64, 64, { hidden: true });
		@:privateAccess hxd.Window.initChars(); // hxd.System does it at startup

		check("р on the H key is H", keys(w, 0x440, SCANCODE_A + 7) == Key.H + "," + Key.H);
		check("д on the L key is L", keys(w, 0x434, SCANCODE_A + 11) == Key.L + "," + Key.L);
		var wrong = [];
		for( i in 0...26 ) {
			var got = keys(w, RUSSIAN.charCodeAt(i), SCANCODE_A + i);
			if( got != (Key.A + i) + "," + (Key.A + i) )
				wrong.push(RUSSIAN.charAt(i) + "=" + got);
		}
		check("every Russian letter is the Latin letter of its key, down and up" + (wrong.length == 0 ? "" : ": " + wrong.join(" ")), wrong.length == 0);
		check("ё on the grave key is QWERTY_TILDE", keys(w, 0x451, SCANCODE_GRAVE) == Key.QWERTY_TILDE + "," + Key.QWERTY_TILDE);

		var latin = true;
		for( i in 0...26 )
			if( keys(w, "a".code + i, SCANCODE_A + i) != (Key.A + i) + "," + (Key.A + i) ) latin = false;
		check("Latin letters keep their key", latin);
		check("numpad Enter keeps its key", keys(w, SCANCODE_MASK | SCANCODE_KP_ENTER, SCANCODE_KP_ENTER) == Key.NUMPAD_ENTER + "," + Key.NUMPAD_ENTER);
		check("a mapped AZERTY character keeps its key", keys(w, 249, 52) == Key.QWERTY_TILDE + "," + Key.QWERTY_TILDE);

		if( failures > 0 ) {
			Sys.println(failures + " check(s) failed");
			Sys.exit(1);
		}
		Sys.println("all checks passed");
	}

	// the hxd.Key codes of the EKeyDown and EKeyUp the window sends for SDL keycode `keyCode` on key `scanCode`
	static function keys( w : hxd.Window, keyCode : Int, scanCode : Int ) {
		var got = [];
		var target = (e : hxd.Event) -> if( e.kind == EKeyDown || e.kind == EKeyUp ) got.push(e.keyCode);
		w.addEventTarget(target);
		@:privateAccess w.onEvent(sdlKey(sdl.Event.EventType.KeyDown, keyCode, scanCode));
		@:privateAccess w.onEvent(sdlKey(sdl.Event.EventType.KeyUp, keyCode, scanCode));
		w.removeEventTarget(target);
		return got.join(",");
	}

	static function sdlKey( type : sdl.Event.EventType, keyCode : Int, scanCode : Int ) {
		var e = new sdl.Event();
		e.type = type;
		e.keyCode = keyCode;
		e.scanCode = scanCode;
		return e;
	}
}
