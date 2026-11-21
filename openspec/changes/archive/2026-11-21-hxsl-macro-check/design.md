# Design

## Context

`hxsl.Macros.makeParser()` produces an HXSL AST and resolves supported Haxe enum types. The shader class build configures its checker with a private loader that resolves Haxe types and parses shader source metadata. Enum path bookkeeping is used by the class build to generate Haxe fields.

## Decisions

- Put the entry point in `hxsl.Macros` so runtime checkers can keep supplying loaders for their own sources. The caller passes an `hxsl.Ast.Expr` and receives `ShaderData`, which can go directly to `hxsl.Serializer`.
- Configure a fresh checker with the same loader and warning callback used by the class build. A private checker factory lets the class build pass its enum path map for field generation. External macros only need the resolved types in their shader data.
- Translate `hxsl.Ast.Error` to Haxe macro errors at the public boundary using the message and source position. Existing Haxe macro errors propagate directly. This produces a positioned compiler diagnostic and lets a resource tool catch the error to add its own context.

## Migration plan

Sprout can parse its block with `hxsl.Macros.makeParser()`, call `hxsl.Macros.checkShader(ref, shader)`, and pass the returned data to its existing serialization step. A resource diagnostic handler can catch `haxe.macro.Expr.Error` for import failures and read `message` and `pos`.
