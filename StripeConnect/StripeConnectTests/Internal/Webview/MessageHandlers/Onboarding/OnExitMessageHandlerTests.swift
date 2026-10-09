//
//  OnExitMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//

@testable import StripeConnect
import XCTest

class OnExitMessageHandlerTests: ScriptWebTestBase {
    @MainActor
    func testMessageSend() async throws {
        let expectation = self.expectation(description: "Message received")
        try await loadTrustedDocument()
        let messageHandler = OnSetterFunctionCalledMessageHandler(sourcePolicy: webView.trustedMessageSourcePolicy(), analyticsClient: MockComponentAnalyticsClient(commonFields: .mock))

        messageHandler.addHandler(handler: OnExitMessageHandler(didReceiveMessage: {
            expectation.fulfill()
        }))

        webView.addMessageHandler(messageHandler: messageHandler)

        try await webView.evaluateSetOnExit()

        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}
