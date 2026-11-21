## 1. Public HXSL checker for macros

- [ ] 1.1 Add and document `hxsl.Macros.checkShader(name, shader)` with the standard loader and warnings. Verify it through `tests/HxslMacroCheckTest.hx` and `haxe all.hxml`.
- [ ] 1.2 Add an external macro regression covering `Base2d` import and serialization, an imported enum parameter, and import diagnostics for non-shader and missing types. Run the command at the top of `tests/HxslMacroCheckTest.hx`.

## Workflow follow-up

- Report the public API and Sprout migration example on HPS-51. Sprout's pin and call site are updated in its own change after landing.
