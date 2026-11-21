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

### Requirement: Report a non-shader extension at the type path

A Haxe macro checking HXSL SHALL report an `@:extends` target with no shader source as a positioned error naming the non-shader type.

#### Scenario: A shader class extends a non-shader type in its source

- **WHEN** a Haxe shader class declares `@:extends String` in its HXSL source
- **THEN** the compiler reports `String is not a shader` at the `String` argument

#### Scenario: An external macro checks a non-shader extension

- **WHEN** an external Haxe macro checks a parsed HXSL block with `@:extends String`
- **THEN** it receives a Haxe macro error with the message `String is not a shader` and the position of the `String` argument
