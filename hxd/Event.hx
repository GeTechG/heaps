package hxd;

enum EventKind {
	EPush;
	ERelease;
	EMove;
	EOver;
	EOut;
	EWheel;
	EFocus;
	EFocusLost;
	EKeyDown;
	EKeyUp;
	EReleaseOutside;
	ETextInput;
	/**
		Used to check if we are still on the interactive if no EMove was triggered this frame.
	**/
	ECheck;
}

@:allow(hxd.Window)
class Event {

	public var kind : EventKind;
	public var relX : Float;
	public var relY : Float;
	public var relZ : Float;
	/**
		Will propagate the event to other interactives that are below the current one.
	**/
	public var propagate : Bool;
	/**
		Will cancel the default behavior for this event as if it had happen outside of the interactive zone.
	**/
	public var cancel : Bool;
	public var button : Int = 0;
	public var touchId : Int;
	public var keyCode : Int;
	public var charCode : Int;
	public var wheelDelta : Float;

	public function new(k,x=0.,y=0.) {
		kind = k;
		this.relX = x;
		this.relY = y;
	}

	public function toString() {
		return kind + "[" + Std.int(relX) + "," + Std.int(relY) + "]" + switch( kind ) {
		case EPush, ERelease, EReleaseOutside: ",button=" + button;
		case EMove, EOver, EOut, EFocus, EFocusLost, ECheck: "";
		case EWheel: ",wheelDelta=" + wheelDelta;
		case EKeyDown, EKeyUp: ",keyCode=" + keyCode;
		case ETextInput: ",charCode=" + charCode;
		}
	}

	static function textInputs( text : String, x : Float, y : Float ) : Array<Event> {
		var events = [];
		for( c in new haxe.iterators.StringIteratorUnicode(text) ) {
			var e = new Event(ETextInput, x, y);
			e.charCode = c;
			events.push(e);
		}
		return events;
	}

	// `expr` if the class `path` has the instance field `field`, `otherwise` if not: code against an API that only some versions of a library have
	static macro function ifHasField( path : String, field : String, expr : haxe.macro.Expr, otherwise : haxe.macro.Expr ) : haxe.macro.Expr {
		return switch( haxe.macro.Context.getType(path) ) {
		case TInst(c, _) if( Lambda.exists(c.get().fields.get(), f -> f.name == field) ): expr;
		default: otherwise;
		}
	}

}