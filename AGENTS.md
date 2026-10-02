# heaps — agent guide

Independent fork of `HeapsIO/heaps` (the Heaps game engine). Its consumers pin it by commit; they do not dictate how it is worked on. This file is the source of truth here.

## Branches and delivery
- One task — one branch, cut from `master`.
- No pull requests (the fork is worked on solo): run the checks on the branch, rebase it on `master`, fast-forward `master` to it (merge if a rebase is impractical) and push `master`.

## Commits
- Every commit is **code** (library sources and tests: `h2d/`, `h3d/`, `hxd/`, `hxsl/`, `samples/`, `tests/`, `tools/`, upstream metadata and workflows) or **infrastructure** (the paths listed in `.github/infra-paths`, absent from upstream: this file, `openspec/`, our CI and scripts). Never both — CI rejects a mixed commit.
- OpenSpec artifacts (proposal, tasks, specs, archive) are infrastructure: they never share a commit with code.
- Code commit messages are written as for upstream `HeapsIO/heaps`: `area: imperative summary` (e.g. `h2d.Text: ...`, `js: ...`), no mention of consumers or their paths.
- An upstream PR is a cherry-pick of one task's code commits; keep them self-contained.
- Changing the list of infrastructure paths is an infrastructure commit.

## Checks
Run before pushing:
- `bash .github/scripts/check-commit-kinds-test.sh` — self-test of the commit-kind check.
- `bash .github/scripts/check-commit-kinds.sh origin/master..HEAD` — the check on your branch.
- For code commits: `haxe all.hxml` (Haxe 4.3.7; libraries as in `.github/workflows/main.yml`), plus any test under `tests/` touched by the change — the run command is the first line of each test file.

## Specs
`openspec/` holds this fork's own specs (`openspec/specs/`). Behaviour or rule changes go through `openspec/changes/`.
