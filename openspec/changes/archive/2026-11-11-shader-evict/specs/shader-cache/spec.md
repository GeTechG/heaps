## ADDED Requirements

### Requirement: evicting a SharedShader forgets its linked shaders
`hxsl.Cache.evict(shader)` SHALL remove from the cache every runtime shader linked from an instance of `shader`, and every batch shader made from one of them, and SHALL leave every other linked shader in place. After the call, linking a list that contains an instance of `shader` SHALL compile a new runtime shader.

#### Scenario: Linked shaders are forgotten
- **WHEN** lists containing instances of `shader` have been linked and `evict(shader)` is called
- **THEN** the call returns those runtime shaders, and linking one of the lists again returns a new runtime shader

#### Scenario: Other shaders stay cached
- **WHEN** `evict(shader)` is called and a list without any instance of `shader` was linked before
- **THEN** linking that list again returns the same runtime shader as before

#### Scenario: A shader never linked
- **WHEN** `evict(shader)` is called for a shader no list containing it was linked with
- **THEN** it returns no runtime shader and releases nothing

### Requirement: evicting releases compiled programs no one shares
`evict(shader, ?driver)` SHALL call `driver.disposeShader` once for each runtime shader id carried by a removed shader and by no shader left in the cache, and never for an id still carried by one. Without a driver it SHALL use the current engine's driver, and none when there is no engine.

#### Scenario: Program of an evicted text
- **WHEN** the only runtime shader with a given id is evicted
- **THEN** `disposeShader` is called with it

#### Scenario: Same text in another SharedShader
- **WHEN** two `SharedShader`s with the same text have been linked in the same lists and the first is evicted
- **THEN** `disposeShader` is not called, and the second's runtime shaders keep their id

#### Scenario: Same text compiled again after eviction
- **WHEN** the only `SharedShader` with a text was evicted and a new one with that text is linked
- **THEN** its runtime shader gets an id no live shader carries

### Requirement: GlDriver deletes a disposed program
`h3d.impl.Driver.disposeShader(shader)` SHALL do nothing by default. `h3d.impl.GlDriver` SHALL delete the GL program compiled for `shader.id` and forget it, and SHALL compile it again from the runtime shader's code if that shader is selected later. `RenderGraphDriver` SHALL forward the call.

#### Scenario: Disposed program
- **WHEN** `disposeShader(rt)` is called on `GlDriver` after `rt` was selected
- **THEN** the program is deleted, and the next draw selects no stale program

#### Scenario: Disposed shader selected again
- **WHEN** `rt` is selected after `disposeShader(rt)`
- **THEN** it is compiled again and draws without a GL error
