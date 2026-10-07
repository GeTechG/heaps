# heaps — agent guide

Independent fork of `HeapsIO/heaps` (the Heaps game engine). Its consumers pin it by commit; they do not dictate how it is worked on. This file is the source of truth here.

## Workflow
No pull requests: this fork is worked on solo. Work lives on branches and lands on `master` by rebase or merge; the only mandatory gate is green checks (see *Checks*) on the exact tree that lands. Work is scheduled by baton — load the `/baton` skill before filing or picking up an issue, or changing an issue's status, labels, `footprint` or blockers.

An issue runs the same seven steps, in order:

1. **OpenSpec change.** Branch `change/<ISSUE-KEY>-<openspec-name>` from `origin/master` — one task, one branch — and write the change under `openspec/changes/`. Skip the OpenSpec change — here and in step 3 — when the work is mechanical, i.e. nothing the project history needs a record of (docs, renames, config, a bug fix that returns behaviour to what a spec already states). Anything else that touches behaviour is not mechanical — the change is mandatory. A missing spec is never a reason to skip: when `openspec/specs/` does not yet cover the behaviour the task touches, the change adds that spec as a new capability, so the next task has it to work against. A skip is never silent: the report on the issue carries the line `OpenSpec skipped: <reason>`. The other steps stay. An issue labeled `gate:spec` stops here: push the artifacts, post a short plan on the issue, add `needs-human`; continue once the maintainer swaps it for `spec:approved`.
2. **Implement** the tasks.
3. **Test.** Verify the implementation against the change, then sync its specs and archive it as the **last commit of the branch** (never a separate push to `master`), rebase onto current `master` and run the checks. Unless the task is trivial (mechanical, or a few obvious lines), finish with a cross-review of the whole branch diff before the checks — `/ai-brainstorm:ai-review`, a judge from another model family — and fix or rebut its findings until clean.
4. **Human QA — only if the change has it.** Steps only a human can do are written `- [ ] N.M [human] …` in `tasks.md`; agents never tick them. If there are any, post them on the issue as a checklist a human can follow cold, add `needs-human` and stop; continue once the maintainer removes the label. No `[human]` tasks → skip.
5. **Merge** into `master`: `git merge --ff-only` for a single commit or a short linear series, `git merge --no-ff` for a multi-commit change. Push `master`. If `master` moved since the checks ran, rebase and run them again first.
6. **Clean up**: delete the branch (local and remote) and its worktree.
7. **Set the issue done.**

The maintainer decides architecture and end-user behaviour, nothing else — steps 1 (`gate:spec`) and 4 are the only points where an agent waits for a human. Work without an issue: mechanical edits may go straight to `master`.

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
- For code commits: `haxe all.hxml`, plus any test under `tests/` touched by the change — the run command is the first line of each test file. `haxe` here is always the pinned compiler (see *Toolchain*).

## Toolchain
`bash tools/setup.sh` provisions a checkout in one command. Run it in every new worktree, after adding, moving or removing source files, and after changing a pin; restart Serena afterwards.

- **Compiler.** A Haxe 5 build of the `GeTechG/haxe` fork, pinned in `tools/haxe-build.pin`: one line, `<build key, 40 hex> <sha256 of the archive, 64 hex>`. Changing the compiler is changing that file, in one commit. The setup downloads the build, verifies the checksum and links it as the git-ignored `.haxe`.
- **Build, type-check and run tests only with it**, never with a system Haxe 4.x or haxelib. Wherever a command says `haxe`, run `PATH="$PWD/tools:$PATH" HAXE_STD_PATH=.haxe/std .haxe/haxe …`. `tools/haxelib` on that `PATH` is what resolves `-lib`: it serves the libraries pinned by commit in `tools/setup.sh`, and nothing else.
- **Serena** (symbol navigation, wired in `.mcp.json` and `.codex/config.toml`) runs a language server on that compiler; the setup builds the server and writes the git-ignored `.serena/lsp.hxml` and `.serena/project.local.yml`. The display config is `all.hxml`'s HashLink/SDL build with every module it includes listed by name — which is why the setup is re-run when files are added.
- **Reference lists from the language server are not exhaustive.** Before renaming or removing a symbol, check them against a text search. Known gaps: code compiled only for another target (JS, DirectX) is not typed; a listed module that stops compiling drops out (the setup fails loudly when `.serena/lsp.hxml` does not compile); and a symbol *declared* in a file with CRLF line endings — most of the sources — returns no references at all.
- Keep each file's line endings. Serena's editing tools write LF, so edit CRLF files with other tools.

## Specs
`openspec/` holds this fork's own specs (`openspec/specs/`). Behaviour or rule changes go through `openspec/changes/`.
