## ADDED Requirements

### Requirement: a uniform array upload names the array's own element count
On a native target, when `h3d.impl.GlDriver` uploads the globals or the params of a shader, the count it passes to `glUniform4fv` SHALL be the number of `vec4` in the uniform array — the shader's `globalsSize` or `paramsSize` — and the data it passes SHALL hold that many `vec4`. It SHALL NOT pass the number of floats.

#### Scenario: Params upload on OpenGL ES
- **WHEN** a shader whose `paramsSize` is 1 is drawn on an OpenGL ES context
- **THEN** `glUniform4fv` is called with a count of 1 and the GL error queue stays empty

#### Scenario: Globals upload
- **WHEN** a shader whose `globalsSize` is N is drawn on a native target
- **THEN** `glUniform4fv` is called for the globals with a count of N, over N * 16 bytes of data

#### Scenario: Desktop OpenGL
- **WHEN** the same scene is drawn on a desktop OpenGL context
- **THEN** the uniform arrays receive the same values as before
