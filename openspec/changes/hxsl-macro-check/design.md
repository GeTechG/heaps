# Design

## Context

`hxsl.Macros.makeParser()` produces an HXSL AST and resolves supported Haxe enum types. The shader class build configures its checker with a private loader that resolves Haxe types and parses shader source metadata. Enum path bookkeeping is used by the class build to generate Haxe fields.

## Decisions

- Put the entry point in `hxsl.Macros` so runtime checkers can keep supplying loaders for their own sources. The caller passes an `hxsl.Ast.Expr` and receives `ShaderData`, which can go directly to `hxsl.Serializer`.
- Configure a fresh checker with the same loader and warning callback used by the class build. A private checker factory lets the class build pass its enum path map for field generation. External macros only need the resolved types in their shader data.
- Let the checker and Haxe macro context propagate import failures. Test both an existing non-shader type and a missing type because the failures originate in different layers.

## Migration plan

Sprout can parse its block with `hxsl.Macros.makeParser()`, call `hxsl.Macros.checkShader(ref, shader)`, and pass the returned data to its existing serialization step.
