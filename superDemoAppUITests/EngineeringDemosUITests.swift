//
//  EngineeringDemosUITests.swift
//  superDemoAppUITests
//
//  Integration / UI smoke for Engineering demos (P0–P2 portfolio surfaces).
//

import XCTest

final class EngineeringDemosUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    override func tearDown() {
        UiTestSupport.terminateApplication(XCUIApplication())
        super.tearDown()
    }

    @MainActor
    func testShareInboxDemoIsReachable() {
        let app = UiTestSupport.launchApplication(from: self)
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "shareInboxDemoLink",
            screenIdentifier: "shareInboxDemoScreen",
            in: app
        )

        XCTAssertTrue(
            UiTestSupport.waitForAnyIdentifier(
                [
                    "shareInboxReload",
                    "shareInboxSeed",
                    "shareInboxClear",
                    "shareInboxAbsent",
                    "shareInboxUnavailable",
                    "shareInboxCorrupt",
                ],
                in: app
            )
        )

        let seed = app.buttons["shareInboxSeed"]
        XCTAssertTrue(seed.waitForExistence(timeout: 10), "Share inbox Seed missing")
        XCTAssertTrue(seed.isHittable, "Share inbox Seed exists but is not hittable")
        seed.tap()

        // After Seed: entry when App Group OK, unavailable when container missing,
        // or honest seed-failed status. Do not accept pre-seed absent/corrupt —
        // that false-greened a silent Seed no-op.
        let afterSeed =
            UiTestSupport.waitForIdentifierPrefix("shareInboxEntry_", in: app, timeout: 15)
                || UiTestSupport.waitForAnyIdentifier(
                    ["shareInboxUnavailable", "shareInboxSeedFailed"],
                    in: app,
                    timeout: 5
                )
        XCTAssertTrue(
            afterSeed,
            "Share inbox Seed did not reach entry / unavailable / seed-failed"
        )
    }

    @MainActor
    func testSignInWithAppleDemoIsReachable() {
        let app = UiTestSupport.launchApplication(from: self)
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "signInWithAppleDemoLink",
            screenIdentifier: "signInWithAppleDemoScreen",
            in: app
        )

        XCTAssertTrue(
            UiTestSupport.waitForAnyIdentifier(
                [
                    "signInWithAppleButton",
                    "signInWithAppleRun",
                    "siwaStatusIdle",
                    "siwaStatusUnavailable",
                ],
                in: app
            )
        )
    }

    @MainActor
    func testOnDeviceVisionDemoRecognizesOrReportsHonestState() {
        let app = UiTestSupport.launchApplication(from: self)
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "onDeviceVisionDemoLink",
            screenIdentifier: "onDeviceVisionDemoScreen",
            in: app
        )

        let run = app.buttons["visionRecognizeRun"]
        XCTAssertTrue(run.waitForExistence(timeout: 10))
        XCTAssertEqual(run.label, "Recognize text in sample image")
        run.tap()

        let finished =
            UiTestSupport.waitForIdentifierPrefix("visionLine_", in: app, timeout: 30)
                || UiTestSupport.waitForAnyIdentifier(
                    [
                        "visionStatusNoText",
                        "visionStatusUnavailable",
                        "visionStatusFailed",
                    ],
                    in: app,
                    timeout: 5
                )
        XCTAssertTrue(finished, "Vision demo did not reach a terminal UI state")
    }

    @MainActor
    func testHostBridgePingDemoReturnsResponse() {
        let app = UiTestSupport.launchApplication(from: self)
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "hostBridgePingDemoLink",
            screenIdentifier: "hostBridgePingDemoScreen",
            in: app
        )

        let ping = app.buttons["hostBridgePingButton"]
        XCTAssertTrue(ping.waitForExistence(timeout: 10))
        ping.tap()

        let response = app.descendants(matching: .any)
            .matching(identifier: "hostBridgeResponseText")
            .firstMatch
        XCTAssertTrue(response.waitForExistence(timeout: 10))

        let deadline = Date().addingTimeInterval(10)
        var label = response.label
        while Date() < deadline {
            let stillWaiting =
                label.contains("Tap Ping")
                    || label.isEmpty
                    || !label.contains(#""ok":true"#)
            guard stillWaiting else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            label = response.label
        }
        // Nonempty / non-placeholder alone false-greened error and ok:false.
        XCTAssertFalse(label.contains("Tap Ping"), "Host bridge response stayed on placeholder")
        XCTAssertTrue(
            label.contains(#""ok":true"#),
            "Expected successful feed.cacheStatus JSON (ok:true), got: \(label)"
        )
        XCTAssertFalse(
            label.contains(#""ok":false"#),
            "Host bridge returned ok:false — not a successful ping: \(label)"
        )
        XCTAssertTrue(
            label.contains(#""id":"demo-1"#),
            "Expected fixed request id demo-1 echoed in response: \(label)"
        )
        XCTAssertTrue(
            label.contains(#""source"#),
            "Expected cache-status result.source in successful response: \(label)"
        )
    }

    @MainActor
    func testFeedWidgetSnapshotDemoIsReachable() {
        let app = UiTestSupport.launchApplication(from: self)
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "feedWidgetSnapshotDemoLink",
            screenIdentifier: "feedWidgetSnapshotDemoScreen",
            in: app
        )

        XCTAssertTrue(
            UiTestSupport.waitForAnyIdentifier(
                ["feedWidgetSnapshotStatus", "feedWidgetSnapshotReload"],
                in: app
            )
        )
    }

    @MainActor
    func testStoreKitProductQueryDemoIsReachable() {
        let app = UiTestSupport.launchApplication(from: self)
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "storeKitProductQueryDemoLink",
            screenIdentifier: "storeKitProductQueryDemoScreen",
            in: app
        )

        let load = app.buttons["storeKitLoadProducts"]
        XCTAssertTrue(load.waitForExistence(timeout: 10), "StoreKit Load missing")
        XCTAssertTrue(load.isHittable, "StoreKit Load exists but is not hittable")
        load.tap()

        // Terminal only — idle/loading after Load previously false-greened.
        let finished =
            UiTestSupport.waitForIdentifierPrefix("storeKitProductRow_", in: app, timeout: 30)
                || UiTestSupport.waitForAnyIdentifier(
                    ["storeKitStatusEmpty", "storeKitStatusUnavailable"],
                    in: app,
                    timeout: 5
                )
        XCTAssertTrue(finished, "StoreKit query did not reach a terminal UI state")
    }

    @MainActor
    func testLocalNotificationDemoIsReachable() {
        let app = UiTestSupport.launchApplication(from: self)
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "localNotificationDemoLink",
            screenIdentifier: "localNotificationDemoScreen",
            in: app
        )

        XCTAssertTrue(
            UiTestSupport.waitForAnyIdentifier(
                [
                    "localNotificationRequestPermission",
                    "localNotificationSchedule",
                    "localNotificationCancel",
                    "localNotificationDeniedHint",
                ],
                in: app
            )
        )
    }

    @MainActor
    func testIdempotentPostDemoIsReachable() {
        let app = UiTestSupport.launchApplication(from: self)
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "idempotentPostDemoLink",
            screenIdentifier: "idempotentPostDemoScreen",
            in: app
        )

        let send = app.buttons["idempotentPostSendButton"]
        XCTAssertTrue(send.waitForExistence(timeout: 10))
        send.tap()

        let outcomeTitle = app.descendants(matching: .any)
            .matching(identifier: "idempotentPostOutcomeTitle")
            .firstMatch
        XCTAssertTrue(outcomeTitle.waitForExistence(timeout: 15))
        // Any outcome title (incl. Failed) was a false-green — require Accepted.
        XCTAssertEqual(
            outcomeTitle.label,
            "Accepted",
            "First send must show Accepted, got: \(outcomeTitle.label)"
        )

        send.tap()
        let deadline = Date().addingTimeInterval(15)
        var label = outcomeTitle.label
        while Date() < deadline, label != "Simulated duplicate-safe" {
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            label = outcomeTitle.label
        }
        XCTAssertEqual(
            label,
            "Simulated duplicate-safe",
            "Second send must prove replay, got: \(label)"
        )
        XCTAssertNotEqual(label, "Failed")
    }

    @MainActor
    func testFlutterAddToAppDemoIsReachable() {
        let app = UiTestSupport.launchApplication(from: self)
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "flutterAddToAppDemoLink",
            screenIdentifier: "flutterAddToAppDemoScreen",
            in: app
        )

        // `openEngineeringDemo` already required `flutterAddToAppDemoScreen`.
        // Outcome must prove embedded **or** unavailable chrome — not the host
        // screen id alone (always present → false green). Prefer staticTexts /
        // buttons so we do not stall on Flutter's semantics tree.
        let embedded = app.staticTexts.matching(identifier: "flutterAddToAppEmbedded").firstMatch
        let unavailable = app.staticTexts.matching(identifier: "flutterAddToAppUnavailable").firstMatch
        let unavailableScreen = app.otherElements
            .matching(identifier: "flutterAddToAppUnavailableScreen")
            .firstMatch
        let hostBridge = app.descendants(matching: .any)
            .matching(identifier: "flutterAddToAppHostBridgeLink")
            .firstMatch
        let sawOutcome =
            embedded.waitForExistence(timeout: 12)
                || unavailable.waitForExistence(timeout: 2)
                || unavailableScreen.waitForExistence(timeout: 2)
                || hostBridge.waitForExistence(timeout: 2)
                || UiTestSupport.waitForAnyIdentifier(
                    [
                        "flutterAddToAppEmbedded",
                        "flutterAddToAppUnavailable",
                        "flutterAddToAppUnavailableScreen",
                        "flutterAddToAppHostBridgeLink",
                    ],
                    in: app,
                    timeout: 8
                )
        XCTAssertTrue(
            sawOutcome,
            "Flutter demo missing embedded or unavailable outcome chrome"
        )

        let screen = app.descendants(matching: .any)
            .matching(identifier: "flutterAddToAppDemoScreen")
            .firstMatch
        if screen.waitForExistence(timeout: 5) {
            let label = screen.label
            XCTAssertTrue(
                label.contains("Flutter") || label.isEmpty,
                "Flutter demo screen should keep a VoiceOver-relevant label when exposed"
            )
        }
    }

    @MainActor
    func testWatchCompanionDemoIsReachable() {
        let app = UiTestSupport.launchApplication(from: self)
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "watchCompanionDemoLink",
            screenIdentifier: "watchCompanionDemoScreen",
            in: app
        )

        XCTAssertTrue(
            UiTestSupport.waitForAnyIdentifier(
                [
                    "watchCompanionDemoTitle",
                    "watchCompanionDemoSummary",
                    "watchCompanionDemoHonesty",
                ],
                in: app
            )
        )

        let title = app.descendants(matching: .any)
            .matching(identifier: "watchCompanionDemoTitle")
            .firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertFalse(title.label.isEmpty, "Watch companion title should expose an accessibility label")
    }

    @MainActor
    func testDiagnosticsDemoIsReachable() {
        let app = UiTestSupport.launchApplication(from: self)
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "diagnosticsDemoLink",
            screenIdentifier: "diagnosticsDemoScreen",
            in: app
        )
    }
}
