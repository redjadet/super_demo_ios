#!/usr/bin/env bash
# iPhone CI test shard definitions. Total coverage must stay identical to the
# unsharded lane (minus the existing CI skip of testLaunchPerformance).
#
# Shards (matrix keys):
#   unit-and-app-ui  — superDemoAppTests + superDemoAppUITests + LaunchTests
#   engineering-a    — first half of EngineeringDemosUITests
#   engineering-b    — second half of EngineeringDemosUITests

ci_iphone_shard_ids() {
  printf '%s\n' unit-and-app-ui engineering-a engineering-b
}

ci_iphone_shard_only_testing_args() {
  local shard="${1:-}"
  case "$shard" in
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
      echo "error: unknown CI_IPHONE_TEST_SHARD='$shard' (expected: $(ci_iphone_shard_ids | paste -sd, -))" >&2
      return 2
      ;;
  esac
}
