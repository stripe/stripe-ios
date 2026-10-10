//
//  DebugMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//

@testable import StripeConnect
import XCTest

class DebugMessageHandlerTests: ScriptWebTestBase {
    func testMessageSend() async throws {
        let expectation = self.expectation(description: "Message received")
        let debugMessage = "test message"
        try await loadTrustedDocument()

        webView.addMessageHandler(messageHandler: DebugMessageHandler(
            sourcePolicy: webView.trustedMessageSourcePolicy(),
            analyticsClient: MockComponentAnalyticsClient(commonFields: .mock),
            didReceiveMessage: { payload in
                expectation.fulfill()
                XCTAssertEqual(payload, debugMessage)
            }
        ))

        webView.evaluateDebugMessage(message: debugMessage)

        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}
