# CI parallel lanes

## Summary

- GitHub Actions now runs lint, iPhone tests, and iPad/Mac platform builds as
  separate parallel jobs.
- The `lint-build-test` job remains as the aggregate required-check gate so branch
  protection can keep using the same check name.
- Local `./bin/ci.sh` remains the full single-command proof with the same lanes.
- `./bin/ci-iphone-test.sh` owns the iPhone build/test lane so local CI and GitHub
  Actions do not duplicate xcodebuild flags.
- The lint job uses `brew bundle check` before `brew bundle` to skip installs when
  tools are already present.
- `tool/resolve_platform_destination.sh` no longer needs `rg`, so test/build lanes
  can resolve simulators before lint tools are installed.
- CI simulator prep accepts `CI_PREPARE_IPHONE=0` / `CI_PREPARE_IPAD=0`; parallel
  lanes only provision the device family they need.

## Proof

```bash
bash -n bin/ci.sh bin/ci-iphone-test.sh bin/ci-platform-builds.sh
shellcheck -e SC1091 bin/ci.sh bin/ci-iphone-test.sh bin/ci-platform-builds.sh tool/ensure_ci_simulator.sh tool/resolve_platform_destination.sh tool/ios_simulator_runtime.sh
actionlint .github/workflows/ci.yml
PATH=/usr/bin:/bin:/usr/sbin:/sbin CI=true CI_PREPARE_IPAD=0 ./tool/ensure_ci_simulator.sh
PATH=/usr/bin:/bin:/usr/sbin:/sbin CI=true CI_PREPARE_IPHONE=0 ./tool/ensure_ci_simulator.sh
./bin/checklist-fast
```
