# Spec Delta

## ADDED Requirements

### Requirement: Report a non-shader extension at the type path

A Haxe macro checking HXSL SHALL report an `@:extends` target with no shader source as a positioned error naming the non-shader type.

#### Scenario: A shader class extends a non-shader type in its source

- **WHEN** a Haxe shader class declares `@:extends String` in its HXSL source
- **THEN** the compiler reports `String is not a shader` at the `String` argument

#### Scenario: An external macro checks a non-shader extension

- **WHEN** an external Haxe macro checks a parsed HXSL block with `@:extends String`
- **THEN** it receives a Haxe macro error with the message `String is not a shader` and the position of the `String` argument
