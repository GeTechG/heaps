## ADDED Requirements

### Requirement: CI builds with the pinned compiler
The fork's own workflow `.github/workflows/ci.yml` SHALL, on every push to any branch, provision the checkout with `bash tools/setup.sh` and build `all.hxml` with the compiler it links as `.haxe`. The job SHALL fail when the setup or the build fails. The upstream workflow `.github/workflows/main.yml` builds with upstream's compilers and SHALL NOT be relied on as this check.

#### Scenario: Tree does not build with the pinned compiler
- **WHEN** a pushed commit does not build `all.hxml` with the pinned compiler
- **THEN** the run of `ci.yml` for that commit fails

#### Scenario: Pins unchanged
- **WHEN** neither `tools/haxe-build.pin` nor `tools/setup.sh` changed since the previous run
- **THEN** the job takes the toolchain from the cache kept between runs and downloads no compiler
