# 2026-10-04 — Fail import-leak guard when Python scanner fails

## Summary

`tool/check_feature_import_leaks.sh` consumed scanner output via process
substitution (`done < <(run_leak_scan …)`), which drops the scanner’s exit
status under bash. A failing Python scanner could print “checks passed” and
exit `0`. Capture stdout to a temp file, check scanner status, then filter;
`--self-test` now includes a scanner-failure regression.
