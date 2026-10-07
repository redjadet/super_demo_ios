#!/usr/bin/env bash
# iPhone CI test shard definitions. Total coverage must stay identical to the
# unsharded lane (minus the existing CI skip of testLaunchPerformance).
#
# Layout (speed-split toward ≤20m wall):
#   unit  — superDemoAppTests only (Swift Testing + XCTest unit; no UI)
#   ui-1…ui-4 — balanced by observed test duration; all UI cases except performance
#
# Also: ui (all UI), ui-a/ui-b (halves), legacy engineering / unit-and-app-ui.

ci_iphone_shard_ids() {
  printf '%s\n' unit ui-1 ui-2 ui-3 ui-4
}

ci_iphone_shard_only_testing_args() {
  local shard="${1:-}"
  case "$shard" in
    unit)
      printf '%s\n' \
        "-only-testing:superDemoAppTests"
      ;;
    ui)
      printf '%s\n' \
        "-only-testing:superDemoAppUITests"
      ;;
    ui-1)
      # Baseline test bodies ~356s; new cases estimated at 70s.
      printf '%s\n' \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testIdempotentPostDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testLocalNotificationDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testStoreKitProductQueryDemoIsReachable" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testDeepLinkOpensFeedPostDetail" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testDeepLinkOpensItemsTab"
      ;;
    ui-2)
      # Baseline test bodies ~367s; new cases estimated at 70s.
      printf '%s\n' \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testHostBridgePingDemoReturnsResponse" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testSignInWithAppleDemoIsReachable" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testDeepLinkOpensFeedTab" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testFeedPostRowOpensDetail" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testLaunchShowsAddItemControl" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testOfflineBookmarkToggleShowsPending" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testUIKitShowcaseCollectionIsReachable"
      ;;
    ui-3)
      # Baseline test bodies ~372s; new cases estimated at 70s.
      printf '%s\n' \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testDiagnosticsDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testFlutterAddToAppDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testTVCompanionDemoIsReachable" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testDashboardShowsProductionRisks" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testFeedTabIsReachable" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testStaleFeedEngineeringDemoShowsBanner" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testStaleFeedFixtureShowsBannerOnFeedTab"
      ;;
    ui-4)
      # Baseline test bodies ~366s; new cases estimated at 70s.
      printf '%s\n' \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testFeedWidgetSnapshotDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testOnDeviceVisionDemoRecognizesOrReportsHonestState" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testShareInboxDemoIsReachable" \
        "-only-testing:superDemoAppUITests/EngineeringDemosUITests/testWatchCompanionDemoIsReachable" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testFeedAccessibilityChromeRowsAndRetry" \
        "-only-testing:superDemoAppUITests/superDemoAppUITests/testItemRowOpensDetail" \
        "-only-testing:superDemoAppUITests/superDemoAppUITestsLaunchTests/testLaunch"
      ;;
    ui-a)
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
      return 0
      ;;
    *)
      echo "error: unknown CI_IPHONE_TEST_SHARD='$shard' (expected: $(ci_iphone_shard_ids | paste -sd, -) or legacy)" >&2
      return 2
      ;;
  esac
}
