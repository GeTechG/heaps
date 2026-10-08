## 1. Setup

- [x] 1.1 `tools/setup.sh`: install `@ast-grep/cli` at the pinned version and build `GeTechG/tree-sitter-haxe` at the pinned commit into the per-user cache; link both into `.ast-grep/`
- [x] 1.2 `sgconfig.yml` registers the grammar for `.hx`; `.gitignore` ignores `.ast-grep/`
- [x] 1.3 `AGENTS.md`: when to use `ast-grep`, Serena, text search

## 2. Verification

- [x] 2.1 With a cold cache the setup installs both; with a warm one it only links
- [x] 2.2 `.ast-grep/ast-grep run -p 'throw new $T($$$A)' -l haxe .` matches what a text search for `throw new ` finds; the number of files with an `ERROR` node is stated
