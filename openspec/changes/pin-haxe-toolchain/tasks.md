## 1. Compiler pin and setup

- [x] 1.1 Add `tools/haxe-build.pin` with the initial build key and checksum
- [x] 1.2 `tools/setup.sh`: download, verify and install the compiler into the user cache, link `.haxe`
- [x] 1.3 `tools/setup.sh`: fetch the libraries `all.hxml` names at pinned commits; `tools/haxelib` resolves `-lib` from them
- [x] 1.4 Ignore `.haxe` and `.haxelib/`

## 2. Serena

- [x] 2.1 `tools/setup.sh`: build the language server from its pinned commit into the user cache
- [x] 2.2 `tools/setup.sh`: generate `.serena/lsp.hxml` (flattened libraries, every module listed) and check that it compiles
- [x] 2.3 `tools/setup.sh`: write `.serena/project.local.yml`, creating a minimal `project.yml` first and refusing to overwrite foreign overrides
- [x] 2.4 Add `.mcp.json` and `.codex/config.toml`

## 3. Rules and verification

- [x] 3.1 `AGENTS.md`: toolchain section, checks run with the pinned compiler
- [x] 3.2 In a clean worktree after one setup run: `.haxe/haxe --version` is the pinned build, `all.hxml` builds, Serena returns references and its log shows `Using --server-connect`
