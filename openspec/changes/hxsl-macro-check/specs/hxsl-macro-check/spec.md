# HXSL macro checking

## Purpose

Allow external Haxe macros to check parsed HXSL blocks and obtain shader data that can be serialized as a resource.

## ADDED Requirements

### Requirement: Check parsed HXSL with standard shader imports

`hxsl.Macros.checkShader(name, shader)` SHALL check a parsed HXSL block in a Haxe macro using the standard shader import resolution and return its `ShaderData`.

#### Scenario: External resource imports a Heaps shader

- **WHEN** an external macro checks a parsed block that imports `h3d.shader.Base2d` and refers to one of its declarations
- **THEN** the checked data includes the imported declaration and can be serialized with `hxsl.Serializer`

#### Scenario: An imported shader declares a Haxe enum

- **WHEN** an external macro checks a block importing a shader with a parameter typed as a supported Haxe enum
- **THEN** the checked data retains the enum type and its constructors

### Requirement: Report ordinary shader import errors

`hxsl.Macros.checkShader` SHALL preserve the diagnostics from standard shader import resolution.

#### Scenario: Import resolves to a non-shader type

- **WHEN** the parsed block imports a Haxe type that has no shader source metadata
- **THEN** the diagnostic identifies the type as a non-shader and points to the import expression

#### Scenario: Import names a missing type

- **WHEN** the parsed block imports a Haxe type that cannot be resolved
- **THEN** the Haxe type-resolution error identifies the missing type
