## ADDED Requirements

### Requirement: The setup provisions ast-grep with a Haxe grammar
The setup SHALL install `ast-grep` at the version pinned in the script and build the tree-sitter grammar `GeTechG/tree-sitter-haxe` at the commit pinned in the script into the per-user cache, one directory per pin, and link them as `ast-grep` and `haxe.so` in the git-ignored `.ast-grep/`. `sgconfig.yml` at the repository root SHALL register that library as the language `haxe` for `.hx` files, so that `.ast-grep/ast-grep run -p '<pattern>' -l haxe <paths>` searches the sources by code shape.

#### Scenario: Fresh worktree
- **WHEN** the setup has run once in a fresh worktree
- **THEN** `.ast-grep/ast-grep --version` reports the pinned version and `.ast-grep/ast-grep run -p 'throw new $T($$$A)' -l haxe .` lists the `throw new` expressions of the sources

#### Scenario: Already installed
- **WHEN** the cache already holds the pinned `ast-grep` and grammar
- **THEN** the setup installs and builds neither and only links them
