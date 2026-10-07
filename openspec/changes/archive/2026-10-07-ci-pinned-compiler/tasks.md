## 1. CI

- [x] 1.1 `.github/workflows/ci.yml`: job that restores the toolchain cache, runs `bash tools/setup.sh` and builds `all.hxml` with the pinned compiler; run on pushes to any branch
- [x] 1.2 `AGENTS.md`: CI builds with the pinned compiler; the upstream workflow stays a compatibility signal

## 2. Verification

- [x] 2.1 The job is green on the branch, with a cold cache and again with a warm one
