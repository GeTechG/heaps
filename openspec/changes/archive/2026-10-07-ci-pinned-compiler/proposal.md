## Why
`AGENTS.md` requires building with the pinned Haxe 5 compiler, but the only build in CI is the upstream workflow `.github/workflows/main.yml`, which installs upstream's own compilers. A green CI run does not show that the tree builds with the pinned compiler; that is checked only locally.

## What Changes
- `.github/workflows/ci.yml` gains a job that runs `bash tools/setup.sh` and builds `all.hxml` with the compiler it provisions. The per-user toolchain cache is saved in the workflow cache, keyed by the pin and the setup script; on a hit the compiler, the libraries and the language server are not fetched or built again.
- The setup runs in CI as it does in a checkout, language server included: no CI-only switch in `tools/setup.sh`, and CI also exercises the setup itself.
- The workflow runs on every branch push, not only on `master`, so a branch is checked before it lands; on a branch the commit-kind check covers `origin/master..HEAD`.
- The upstream matrix in `main.yml` stays as it is: a signal of upstream compatibility, not the gate.
- `AGENTS.md`: says what CI builds.

## Capabilities

### New Capabilities

### Modified Capabilities
- `dev-toolchain`: CI builds `all.hxml` with the pinned compiler.

## Impact
`.github/workflows/ci.yml`, `AGENTS.md`. No library source changes. A CI run with a cold cache builds the language server (node, npm, network).
