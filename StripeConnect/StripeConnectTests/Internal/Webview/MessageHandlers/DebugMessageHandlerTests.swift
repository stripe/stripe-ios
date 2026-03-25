//
//  DebugMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//

@testable import StripeConnect
import XCTest

class DebugMessageHandlerTests: ScriptWebTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        let debugMessage = "test message"

        webView.addMessageHandler(messageHandler: DebugMessageHandler(
            analyticsClient: MockComponentAnalyticsClient(commonFields: .mock),
            didReceiveMessage: { payload in
                expectation.fulfill()
                XCTAssertEqual(payload, debugMessage)
            }
        ))

        webView.evaluateDebugMessage(message: debugMessage)

        waitForExpectations(timeout: TestHelpers.defaultTimeout, handler: nil)
    }
}
