## Why
The fork does not say which compiler builds it, and symbol navigation is not wired: an agent type-checks with whatever Haxe 4.x the machine has and works without references. The fork targets Haxe 5, whose builds and language server are not installable from the usual channels.

## What Changes
- Pin the compiler in the repository: `tools/haxe-build.pin` names a build of the `GeTechG/haxe` fork and the checksum of its archive.
- Add one setup command, `tools/setup.sh`, that provisions a checkout: the pinned compiler behind a git-ignored `.haxe` link, the libraries `all.hxml` names at pinned commits, a language server built from a pinned commit, and Serena's git-ignored local configuration.
- Add `tools/haxelib`, a stand-in that resolves `-lib` from those pinned libraries (the compiler build carries no haxelib).
- Wire Serena for Claude Code (`.mcp.json`) and Codex (`.codex/config.toml`).
- `AGENTS.md`: build, type-check and test only with the pinned compiler; language-server reference lists are not exhaustive.

## Capabilities

### New Capabilities
- `dev-toolchain`: the pinned compiler, the one-command setup of a checkout and the language-server configuration it generates.

### Modified Capabilities

## Impact
New files under `tools/`, `.mcp.json`, `.codex/config.toml`; `.gitignore` gains `.haxe` and `.haxelib/`. No library source changes. The setup needs network access, `curl`, `sha256sum`, `tar`, `flock`, `git`, `node` and `npm`, and supports Linux x86_64 only (the only published build).
