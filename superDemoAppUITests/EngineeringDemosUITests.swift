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
        let app = UiTestSupport.launchApplication()
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
        if seed.waitForExistence(timeout: 5), seed.isHittable {
            seed.tap()
            XCTAssertTrue(
                UiTestSupport.waitForAnyIdentifier(
                    ["shareInboxAbsent", "shareInboxUnavailable", "shareInboxCorrupt"],
                    in: app,
                    timeout: 10
                )
                    || UiTestSupport.waitForIdentifierPrefix("shareInboxEntry_", in: app, timeout: 10)
            )
        }
    }

    @MainActor
    func testSignInWithAppleDemoIsReachable() {
        let app = UiTestSupport.launchApplication()
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
        let app = UiTestSupport.launchApplication()
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "onDeviceVisionDemoLink",
            screenIdentifier: "onDeviceVisionDemoScreen",
            in: app
        )

        let run = app.buttons["visionRecognizeRun"]
        XCTAssertTrue(run.waitForExistence(timeout: 10))
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
        let app = UiTestSupport.launchApplication()
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
        while Date() < deadline, label.contains("Tap Ping") || label.isEmpty {
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            label = response.label
        }
        XCTAssertFalse(label.contains("Tap Ping"), "Host bridge response stayed on placeholder")
        XCTAssertFalse(label.isEmpty)
    }

    @MainActor
    func testFeedWidgetSnapshotDemoIsReachable() {
        let app = UiTestSupport.launchApplication()
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
        let app = UiTestSupport.launchApplication()
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "storeKitProductQueryDemoLink",
            screenIdentifier: "storeKitProductQueryDemoScreen",
            in: app
        )

        let load = app.buttons["storeKitLoadProducts"]
        XCTAssertTrue(load.waitForExistence(timeout: 10))
        load.tap()

        XCTAssertTrue(
            UiTestSupport.waitForAnyIdentifier(
                [
                    "storeKitStatusIdle",
                    "storeKitStatusLoading",
                    "storeKitStatusEmpty",
                    "storeKitStatusUnavailable",
                ],
                in: app,
                timeout: 20
            )
                || UiTestSupport.waitForIdentifierPrefix("storeKitProductRow_", in: app, timeout: 5)
        )
    }

    @MainActor
    func testLocalNotificationDemoIsReachable() {
        let app = UiTestSupport.launchApplication()
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
        let app = UiTestSupport.launchApplication()
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "idempotentPostDemoLink",
            screenIdentifier: "idempotentPostDemoScreen",
            in: app
        )

        let send = app.buttons["idempotentPostSendButton"]
        XCTAssertTrue(send.waitForExistence(timeout: 10))
        send.tap()

        XCTAssertTrue(
            UiTestSupport.waitForAnyIdentifier(
                ["idempotentPostOutcomeTitle", "idempotentPostOutcomeDetail"],
                in: app,
                timeout: 15
            )
        )
    }

    @MainActor
    func testFlutterAddToAppDemoIsReachable() {
        let app = UiTestSupport.launchApplication()
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "flutterAddToAppDemoLink",
            screenIdentifier: "flutterAddToAppDemoScreen",
            in: app
        )

        // Embedded FlutterViewController often does not expose SwiftUI identifiers to XCTest;
        // accept the host screen id (always set) plus unavailable / bridge chrome.
        XCTAssertTrue(
            UiTestSupport.waitForAnyIdentifier(
                [
                    "flutterAddToAppDemoScreen",
                    "flutterAddToAppEmbedded",
                    "flutterAddToAppUnavailable",
                    "flutterAddToAppUnavailableScreen",
                    "flutterAddToAppHostBridgeLink",
                ],
                in: app,
                timeout: 20
            )
        )
    }

    @MainActor
    func testDiagnosticsDemoIsReachable() {
        let app = UiTestSupport.launchApplication()
        UiTestSupport.openEngineeringDemo(
            linkIdentifier: "diagnosticsDemoLink",
            screenIdentifier: "diagnosticsDemoScreen",
            in: app
        )
    }
}
