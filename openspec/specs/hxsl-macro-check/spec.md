# hxsl-macro-check Specification

## Purpose

Allow external Haxe macros to check parsed HXSL blocks and obtain shader data that can be serialized as a resource.

## Requirements

### Requirement: Check parsed HXSL with standard shader imports

`hxsl.Macros.checkShader(name, shader)` SHALL check a parsed HXSL block in a Haxe macro using the standard shader import resolution and return its `ShaderData`.

#### Scenario: External resource imports a Heaps shader

- **WHEN** an external macro checks a parsed block that imports `h3d.shader.Base2d` and refers to one of its declarations
- **THEN** the checked data includes the imported declaration and can be serialized with `hxsl.Serializer`

#### Scenario: An imported shader declares a Haxe enum

- **WHEN** an external macro checks a block importing a shader with a global typed as a supported Haxe enum and uses one of its constructors
- **THEN** the checker type-checks the constructor against the enum and returns shader data with the enum represented as an integer

### Requirement: Report ordinary shader import errors

`hxsl.Macros.checkShader` SHALL report failed imports as positioned Haxe macro errors with the messages provided by standard shader import resolution.

#### Scenario: Import resolves to a non-shader type

- **WHEN** the parsed block imports a Haxe type that has no shader source metadata
- **THEN** the diagnostic identifies the type as a non-shader and points to the import expression

#### Scenario: Import names a missing type

- **WHEN** the parsed block imports a Haxe type that cannot be resolved
- **THEN** the Haxe type-resolution error identifies the missing type
