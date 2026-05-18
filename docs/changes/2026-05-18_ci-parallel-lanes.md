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

## Proof

```bash
bash -n bin/ci.sh bin/ci-iphone-test.sh bin/ci-platform-builds.sh
actionlint .github/workflows/ci.yml
./bin/checklist-fast
```
