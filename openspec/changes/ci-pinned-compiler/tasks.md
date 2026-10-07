## 1. CI

- [ ] 1.1 `.github/workflows/ci.yml`: job that restores the toolchain cache, runs `bash tools/setup.sh` and builds `all.hxml` with the pinned compiler; `workflow_dispatch` trigger
- [ ] 1.2 `AGENTS.md`: CI builds with the pinned compiler; the upstream workflow stays a compatibility signal

## 2. Verification

- [ ] 2.1 The job is green on the branch, started by hand, with a cold cache and again with a warm one
