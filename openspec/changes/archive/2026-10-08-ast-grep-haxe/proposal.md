## Why
An agent in a checkout can find a symbol (Serena) or a string (text search), but cannot search the Haxe sources by code shape: `ast-grep` knows no Haxe without a grammar, and the checkout carries neither the grammar nor a config.

## What Changes
- `tools/setup.sh` installs `ast-grep` at a pinned version (the npm package `@ast-grep/cli`; node and npm are already needed for the language server) and builds the grammar `GeTechG/tree-sitter-haxe` at a pinned commit with the system C compiler. Both go into the per-user toolchain cache, one directory per pin, and are linked into the git-ignored `.ast-grep/`.
- `sgconfig.yml` at the root registers the grammar for `.hx` files.
- `AGENTS.md`: when to reach for `ast-grep`, Serena or a text search.
- No lint rules and no stage in the checks: that is a separate task, once there is a convention worth checking.

## Capabilities

### New Capabilities

### Modified Capabilities
- `dev-toolchain`: the setup provisions `ast-grep` with a Haxe grammar.

## Impact
`tools/setup.sh`, `sgconfig.yml`, `.gitignore`, `AGENTS.md`. No library source changes. The setup now also needs `cc`; a cold cache adds one npm install and a C build of about a second, in CI too.
