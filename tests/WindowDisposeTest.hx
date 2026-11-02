// Run: haxe -cp . -cp tests -lib format --main WindowDisposeTest --js test.js && node test.js
// hxd.Window.dispose on js: every listener the window added is removed from the canvas, the window and the document, for each way a window is built; what the listeners did while attached stays as it was. A DOM stub that counts listeners stands in for the browser under node.
class WindowDisposeTest {
	static var fails = 0;
	static function check(name : String, ok : Bool, ?extra : Dynamic) {
		js.Syntax.code("console.log({0})", (ok ? "ok   " : "FAIL ") + name + (extra != null && !ok ? " " + Std.string(extra) : ""));
		if( !ok ) fails++;
	}
	static function count(t : Dynamic) : Int return js.Syntax.code("{0}.count()", t);
	static function types(t : Dynamic) : String return js.Syntax.code("{0}.types()", t);
	static function fire(t : Dynamic, type : String) js.Syntax.code("{0}.fire({1})", t, type);
	static function newCanvas() : Dynamic return js.Syntax.code("new Target('canvas')");

	static function eventsOf(w : hxd.Window) {
		var got = [];
		w.addEventTarget(e -> got.push(e.kind));
		return got;
	}
	static function fireAll(canvas : Dynamic) {
		var inputs = ["mousedown","mouseup","mouseleave","mousemove","wheel","touchstart","touchmove","touchend","keydown","keyup","keypress","blur","focus","pointerdown","pointerup","contextmenu","compositionupdate","compositionend","dragover","drop"];
		for( t in inputs ) {
			fire(canvas, t);
			fire(js.Browser.window, t);
		}
		fire(js.Browser.window, "resize");
		fire(js.Browser.document, "pointerlockchange");
	}
	static function clean(name : String, canvas : Dynamic, before : Int, beforeDoc : Int) {
		check(name + ": canvas clean", count(canvas) == 0, types(canvas));
		check(name + ": window clean", count(js.Browser.window) == before, types(js.Browser.window));
		check(name + ": document clean", count(js.Browser.document) == beforeDoc, types(js.Browser.document));
	}

	static function setup(name : String, make : Dynamic -> hxd.Window, canvas : Dynamic) {
		var bw = count(js.Browser.window), bd = count(js.Browser.document);
		var w = make(canvas);
		var got = eventsOf(w);
		var added = [];
		w.addDragAndDropTarget(e -> added.push(e));
		check(name + ": listens before dispose", count(canvas) + count(js.Browser.window) > bw);
		fireAll(canvas);
		check(name + ": receives before dispose", got.length > 0);
		w.dispose();
		clean(name, canvas, bw, bd);
		got.splice(0, got.length);
		added.splice(0, added.length);
		js.Syntax.code("Target.defaultPrevented = 0");
		fireAll(canvas);
		check(name + ": nothing after dispose", got.length == 0, got);
		check(name + ": no drop target after dispose", added.length == 0, added);
		check(name + ": no preventDefault after dispose", js.Syntax.code("Target.defaultPrevented") == 0);
		w.dispose();
		check(name + ": second dispose is harmless", count(canvas) == 0);
	}

	static function main() {
		var custom = newCanvas();
		setup("custom", c -> new hxd.Window(c), custom);
		var def = newCanvas();
		js.Syntax.code("document.byId = {0}", def);
		setup("default", c -> new hxd.Window(), def);
		setup("global", c -> new hxd.Window(c, true), newCanvas());
		js.Syntax.code("document.byId = {0}", def);
		def.setAttribute("globalEvents", "1");
		setup("default+global", c -> new hxd.Window(), def);

		// the same canvas, second window
		for( global in [false, true] ) {
			var c = newCanvas();
			var a = new hxd.Window(c, global);
			var ga = eventsOf(a);
			a.dispose();
			var b = new hxd.Window(c, global);
			var gb = eventsOf(b);
			var n = count(c);
			fire(c, "mousedown");
			check('reuse global=$global: old silent', ga.length == 0, ga);
			check('reuse global=$global: new receives', gb.length > 0);
			check('reuse global=$global: new propagation untouched', n == count(c));
			b.dispose();
			check('reuse global=$global: clean', count(c) == 0, types(c));
		}

		// behaviour kept: what the former closures did
		var c = newCanvas();
		var w = new hxd.Window(c, true);
		var g = eventsOf(w);
		js.Syntax.code("Target.defaultPrevented = Target.stopped = 0");
		fire(c, "mousedown");
		check("global: first mousedown on canvas sends, stops, prevents", g.length == 1 && js.Syntax.code("Target.stopped") > 0 && js.Syntax.code("Target.defaultPrevented") > 0, g);
		js.Syntax.code("Target.defaultPrevented = Target.stopped = 0");
		fire(js.Browser.window, "contextmenu");
		check("global: contextmenu on window prevented", js.Syntax.code("Target.defaultPrevented") > 0);
		js.Syntax.code("Target.stopped = 0; Target.defaultPrevented = 0; Target.button = 2");
		fire(c, "contextmenu");
		check("contextmenu on canvas: right button prevented", js.Syntax.code("Target.stopped") > 0 && js.Syntax.code("Target.defaultPrevented") > 0);
		js.Syntax.code("Target.button = 0");
		w.dispose();
		var f = new hxd.Window(newCanvas());
		var g2 = eventsOf(f);
		var cv : Dynamic = @:privateAccess f.canvas;
		fire(cv, "focus");
		check("focus sends EFocus", g2.length == 1 && g2[0] == EFocus, g2);
		fire(cv, "blur");
		check("blur sends EFocusLost", g2.length == 2 && g2[1] == EFocusLost, g2);
		f.dispose();

		// no browser: the constructor adds nothing, dispose has nothing to do
		js.Syntax.code("window.location = undefined");
		check("stub: browser is off", !js.Browser.supported);
		var off = new hxd.Window();
		off.dispose();
		check("no browser: dispose returns", true);
		js.Syntax.code("window.location = { protocol: 'http:' }");

		if( fails > 0 ) { js.Syntax.code("console.log({0}); process.exit(1)", fails + " FAILED"); }
		js.Syntax.code("console.log('all passed')");
	}

	static function __init__() {
		js.Syntax.code("
			globalThis.Target = class Target {
				constructor(name) { this.name = name; this.ls = new Map(); this.style = {}; this.attrs = {}; }
				addEventListener(t, f) { if (!this.ls.has(t)) this.ls.set(t, new Set()); this.ls.get(t).add(f); }
				removeEventListener(t, f) { const s = this.ls.get(t); if (s) { s.delete(f); if (!s.size) this.ls.delete(t); } }
				count() { let n = 0; for (const s of this.ls.values()) n += s.size; return n; }
				types() { return [...this.ls.keys()].join(','); }
				fire(t) {
					const e = { type: t, button: Target.button, buttons: 0, which: 1, clientX: 0, clientY: 0, deltaY: 1, deltaMode: 0, pointerId: 0, changedTouches: [], keyCode: 65, charCode: 65, location: 0, data: '', target: this, dataTransfer: { files: [{ name: 'f', size: 0 }] },
						preventDefault() { Target.defaultPrevented++; }, stopPropagation() { Target.stopped++; } };
					for (const f of [...(this.ls.get(t) || [])]) f(e);
				}
				getAttribute(a) { return a in this.attrs ? this.attrs[a] : null; }
				setAttribute(a, v) { this.attrs[a] = v; }
				getBoundingClientRect() { return { width: 100, height: 100, left: 0, top: 0 }; }
				get clientWidth() { return 100; } get clientHeight() { return 100; }
			};
			Target.defaultPrevented = 0; Target.stopped = 0; Target.button = 0;
			globalThis.window = new Target('window');
			globalThis.document = window.document = new Target('document');
			Object.assign(window, { devicePixelRatio: 1, location: { protocol: 'http:' }, navigator: {} });
			document.getElementById = () => document.byId;
			document.body = new Target('body');
			globalThis.location = window.location;
		");
	}
}
