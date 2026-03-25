//
//  CloseWebViewMessageHandlerTests.swift
//  StripeConnect
//
//  Created by Chris Mays on 2/12/25.
//

@testable import StripeConnect
import XCTest

class CloseWebViewMessageHandlerTests: ScriptWebTestBase {

    @MainActor
    func testMessageSend() async throws {
        let expectation = self.expectation(description: "Message received")

        let messageHandler = CloseWebViewMessageHandler(analyticsClient: MockComponentAnalyticsClient(commonFields: .mock), didReceiveMessage: { _ in
            expectation.fulfill()
        })

        webView.addMessageHandler(messageHandler: messageHandler)

        try await webView.evaluateMessage(name: "closeWebView",
                                          json: """
                                  {}
                                  """)
        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}
