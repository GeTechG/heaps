// Run: haxe -cp . -cp tests -lib format --main HxslMacroCheckTest --interp

#if macro
import haxe.macro.Context;
#end

#if !macro
enum HxslMacroCheckMode {
	First;
	Second;
}

class HxslMacroCheckEnumShader extends hxsl.Shader {
	static var SRC = {
		@global var mode : HxslMacroCheckMode;
	};
}
#end

class HxslMacroCheckTest {
	static function main() {
		checkImports();
		Sys.println("HxslMacroCheckTest: OK");
	}

	static macro function checkImports() {
		var parser = hxsl.Macros.makeParser();
		var shader = parser.parseExpr(macro {
			@:import h3d.shader.Base2d;
			@:import HxslMacroCheckTest.HxslMacroCheckEnumShader;
			function fragment() {
				if( mode == Second ) pixelColor *= 0.5;
			}
		});
		var data = hxsl.Macros.checkShader("MacroResource", shader);
		var decoded = new hxsl.Serializer().unserialize(hxsl.Serializer.run(data));
		if( decoded.name != "MacroResource" || !Lambda.exists(decoded.vars, v -> v.name == "pixelColor") )
			throw "Imported Base2d variable missing from the resource";
		if( !Lambda.exists(decoded.vars, v -> v.name == "mode" && v.type.match(TInt)) )
			throw "Imported enum global missing from the resource";

		var nonShaders = [
			macro { @:import String; },
			macro { @:extends String; },
		];
		for( source in nonShaders ) {
			var nonShader = parser.parseExpr(source);
			var expectedPos = switch( nonShader.expr ) {
			case EBlock([{ expr: ECall(_, [path]) }]): Context.getPosInfos(path.pos);
			default: throw "Expected a shader directive";
			};
			try {
				hxsl.Macros.checkShader("NonShader", nonShader);
				throw "Non-shader directive succeeded";
			} catch( error : haxe.macro.Expr.Error ) {
				var pos = Context.getPosInfos(error.pos);
				if( error.message != "String is not a shader" || pos.file != expectedPos.file ||
					pos.min != expectedPos.min || pos.max != expectedPos.max )
					throw error;
			}
		}

		var missing = parser.parseExpr(macro { @:import h3d.shader.HxslMacroCheckMissingShader; });
		var missingMessage = "Type not found 'h3d.shader.HxslMacroCheckMissingShader'";
		try {
			hxsl.Macros.checkShader("Missing", missing);
			throw "Missing shader import succeeded";
		} catch( error : haxe.macro.Expr.Error ) {
			if( error.message != missingMessage )
				throw error;
		}
		return macro null;
	}
}
