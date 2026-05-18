# Fastlane CI wrapper hardening

## Summary

- Fastlane remains a thin orchestration layer over repo-owned `bin/` and `tool/`
  scripts.
- `run_repo_script` now restores temporary lane environment variables after each
  script. This prevents simulator-prep flags from leaking between `platform_builds`
  and `iphone_test` inside the `ci` lane.
- Confirmed generated Fastlane outputs (`fastlane/report.xml`, generated README, and
  `vendor/bundle`) stay ignored and out of source-of-truth docs.
- Docs prefer `./bin/fastlane-run <lane>` so local runs use Bundler bootstrap and
  the pinned Gemfile.

## Proof

```bash
bundle exec ruby -c fastlane/Fastfile
bundle exec fastlane lanes
./bin/fastlane-run ci_lint
```
