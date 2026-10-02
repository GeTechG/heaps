#!/usr/bin/env bash
# Self-test: a code-only and an infra-only commit pass, a mixed one fails.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
cd "$t"
git init -q; git config user.email t@t; git config user.name t
mkdir -p .github h2d openspec
cp "$here/../infra-paths" .github/infra-paths
echo a > h2d/a.hx; git add -A; git commit -qm base
base=$(git rev-parse HEAD)
echo b >> h2d/a.hx; git commit -qam code
echo c > AGENTS.md; echo d > openspec/x.md; git add -A; git commit -qm infra
"$here/check-commit-kinds.sh" "$base..HEAD" || { echo "FAIL: clean history rejected"; exit 1; }
ok=$(git rev-parse HEAD)
echo e >> h2d/a.hx; echo f >> AGENTS.md; git commit -qam mixed
if "$here/check-commit-kinds.sh" "$ok..HEAD"; then echo "FAIL: mixed commit accepted"; exit 1; fi
echo "ok"
