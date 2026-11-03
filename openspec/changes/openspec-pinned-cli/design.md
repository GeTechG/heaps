## Context
OpenSpec 1.16.0 is installed globally on the maintainer's machine, one version for every repository; CI has no OpenSpec at all. The repository already keeps the `baton` skill in `.agents/skills/baton` with a per-skill symlink from `.claude/skills/`.

## Decisions
- **Two generated copies, no symlinks.** The CLI writes different text for Claude Code (`/openspec-…`) and Codex (`$openspec-… (Codex) or /openspec-… (other agents)`), so one directory cannot serve both. Both are committed exactly as `openspec init` / `openspec update` writes them, so regenerating is one command with no hand edits.
- **The check is a script, the job only calls it.** `.github/scripts/check-openspec.sh` holds every rule, so an agent runs the same check locally before pushing. It uses the global `openspec` when its version equals the pin and otherwise `npm exec --yes --package=@fission-ai/openspec@<pin> -- openspec`; `OPENSPEC` overrides the command. CI always takes the `npm exec` path (the runner has no global install), on Node 24 (the CLI needs ≥ 22.12).
- **Archived human tasks are checked by the script, not by `openspec validate --archived`.** That command reports every unticked task, `[human]` ones included, and an open `[human]` task in the archive is allowed by the workflow.
- **Over-long requirements are rewritten in the main specs directly**, not through MODIFIED deltas: the behaviour does not change, only where its details are written (text → scenarios), and fifteen full-copy deltas would bury the change. The rewrite is a separate commit on this branch.
- **Skill directories become infrastructure.** They do not exist upstream; leaving them as code would force every skill regeneration to pose as library code.

## Risks
- `npm exec` downloads the CLI on every run; acceptable for a job of a few seconds, no cache.
