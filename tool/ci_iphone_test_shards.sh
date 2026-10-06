#!/usr/bin/env bash
# iPhone CI test shard definitions. Total coverage must stay identical to the
# unsharded lane (minus the existing CI skip of testLaunchPerformance).
#
# Layout (speed-split):
#   unit   — superDemoAppTests only (Swift Testing + XCTest unit; no UI)
#   ui-a   — balanced half of UI XCTest (~12 cases)
#   ui-b   — balanced half of UI XCTest (~12 cases)
#
# Legacy aliases kept for docs/local escapes:
#   unit-and-app-ui / engineering-a / engineering-b

ci_iphone_shard_ids() {
  printf '%s\n' unit ui ui-a ui-b
}

ci_iphone_shard_only_testing_args() {
  local shard="${1:-}"
  case "$shard" in
    unit)
      printf '%s\n' \
        "-only-testing:superDemoAppTests"
      ;;
    ui)
      # All UI XCTest (24 cases); caller still skips testLaunchPerformance on CI.
      printf '%s\n' \
        "-only-testing:superDemoAppUITests"
      ;;
    ui-a)
      # ~12 UI cases — heavier demos + a few app UI (balanced vs ui-b by prior timings)
      printf '%s\n' \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testDashboardShowsProductionRisks" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testDeepLinkOpensFeedPostDetail" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testDeepLinkOpensItemsTab" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testFeedTabIsReachable" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testLaunchShowsAddItemControl" \
        "-only-testing:superDemoAppUITests/superDemoAppUITestsLaunchTests/testLaunch" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testOnDeviceVisionDemoRecognizesOrReportsHonestState" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testStoreKitProductQueryDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testLocalNotificationDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testIdempotentPostDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testFlutterAddToAppDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testHostBridgePingDemoReturnsResponse"
      ;;
    ui-b)
      printf '%s\n' \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testDeepLinkOpensFeedTab" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testFeedAccessibilityChromeRowsAndRetry" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testFeedPostRowOpensDetail" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testItemRowOpensDetail" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testStaleFeedEngineeringDemoShowsBanner" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testStaleFeedFixtureShowsBannerOnFeedTab" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testUIKitShowcaseCollectionIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testShareInboxDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testSignInWithAppleDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testFeedWidgetSnapshotDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testWatchCompanionDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testDiagnosticsDemoIsReachable"
      ;;
    # Legacy 3-way split (kept for local comparison / rollback).
    unit-and-app-ui)
      printf '%s\n' \
        "-only-testing:superDemoAppTests" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests" \
        "-only-testing:superDemoAppUITests/superDemoAppUITestsLaunchTests"
      ;;
    engineering-a)
      printf '%s\n' \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testShareInboxDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testSignInWithAppleDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testOnDeviceVisionDemoRecognizesOrReportsHonestState" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testHostBridgePingDemoReturnsResponse" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testFeedWidgetSnapshotDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testStoreKitProductQueryDemoIsReachable"
      ;;
    engineering-b)
      printf '%s\n' \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testLocalNotificationDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testIdempotentPostDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testFlutterAddToAppDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testWatchCompanionDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testDiagnosticsDemoIsReachable"
      ;;
    "")
      # Full suite (no -only-testing). Caller still applies CI LaunchPerformance skip.
      return 0
      ;;
    *)
      echo "error: unknown CI_IPHONE_TEST_SHARD='$shard' (expected: $(ci_iphone_shard_ids | paste -sd, -) or legacy)" >&2
      return 2
      ;;
  esac
}
