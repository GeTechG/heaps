## 1. Pin and skills
- [x] 1.1 Add `openspec/cli.pin` = `1.16.0`; check: `cat openspec/cli.pin` is one `MAJOR.MINOR.PATCH` line
- [x] 1.2 Generate the ten OpenSpec skills with the pinned CLI (`openspec init --tools claude,codex --profile custom`) into `.claude/skills/` and `.agents/skills/`; check: every `openspec-*/SKILL.md` says `generatedBy: "1.16.0"`
- [x] 1.3 List `.claude/skills/` and `.agents/skills/` in `.github/infra-paths`; check: `bash .github/scripts/check-commit-kinds.sh origin/master..HEAD`

## 2. Specs pass strict validation
- [x] 2.1 Rewrite the 15 requirements longer than 500 characters (app-lifecycle, gamepad-input, gl-context-reset, gl-driver-gles, h2d-text, scene-viewport, sound-manager, sound-pan, sound-reverb ×2, text-input ×4, window-dispose) without changing behaviour; check: `openspec validate --specs --strict` passes

## 3. CI check
- [x] 3.1 Write `openspec/check.sh`: pin format, strict validation, no `TBD` Purpose, `.openspec.yaml` in every active change, skills' `generatedBy` = pin, no unticked non-`[human]` archived task; check: it passes on the branch and fails on each defect planted in a scratch copy
- [x] 3.2 Add the `openspec` job to `.github/workflows/ci.yml` running the script with the pinned CLI via `npm exec`; check: the job is green on the pushed branch

## 4. Rules and docs
- [x] 4.1 Add `rules.specs`, `rules.tasks`, `operations.apply` and `operations.archive` to `openspec/config.yaml`; check: `openspec instructions specs --change openspec-pinned-cli` shows the rules, and the check passes
- [x] 4.2 Record the pin, the bump procedure, the skills and the check in `AGENTS.md`; check: read against the spec of this change

## Workflow follow-up
- Report on HPS-46; merge into `master`, delete the branch and worktree.
