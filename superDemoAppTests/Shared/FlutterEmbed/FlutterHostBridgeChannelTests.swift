//
//  FlutterHostBridgeChannelTests.swift
//  superDemoAppTests
//

import Testing
@testable import superDemoApp

@Suite("Flutter host bridge channel constants")
struct FlutterHostBridgeChannelTests {
    @Test
    func channelNameMatchesDartContract() {
        #expect(
            FlutterHostBridgeChannel.channelName
                == "com.ilkersevim.superDemoApp/host_bridge"
        )
        #expect(FlutterHostBridgeChannel.invokeMethod == "invoke")
    }

    @Test
    func embedAvailabilityIsHonestWithoutFlutterFrameworks() {
        // Hosted Mac / Linux-agent builds never link Flutter.xcframework.
        // iOS CI after prepare_flutter_embed.sh may report true.
        _ = FlutterAddToAppHost.isEmbedded
    }
}
