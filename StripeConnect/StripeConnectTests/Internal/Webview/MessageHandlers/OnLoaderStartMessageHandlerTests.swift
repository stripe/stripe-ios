//
//  OnLoaderStartMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//

@testable import StripeConnect
import XCTest

class OnLoaderStartMessageHandlerTests: ScriptWebTestBase {
    @MainActor
    func testMessageSend() async throws {
        let expectation = self.expectation(description: "Message received")
        try await loadTrustedDocument()

        let messageHandler = OnSetterFunctionCalledMessageHandler(sourcePolicy: webView.trustedMessageSourcePolicy(), analyticsClient: MockComponentAnalyticsClient(commonFields: .mock))

        messageHandler.addHandler(handler: OnLoaderStartMessageHandler(didReceiveMessage: { payload in
            expectation.fulfill()

            XCTAssertEqual(payload, OnLoaderStartMessageHandler.Values(elementTagName: "onboarding"))
        }))

        webView.addMessageHandler(messageHandler: messageHandler)

        try await webView.evaluateOnLoaderStart(elementTagName: "onboarding")

        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}
