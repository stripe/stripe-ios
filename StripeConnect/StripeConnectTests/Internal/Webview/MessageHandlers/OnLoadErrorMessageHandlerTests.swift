//
//  OnLoadErrorMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//
@testable import StripeConnect
import XCTest

class OnLoadErrorMessageHandlerTests: ScriptWebTestBase {

    @MainActor
    func testMessageSend() async throws {
        let expectation = self.expectation(description: "Message received")
        let messageHandler = OnSetterFunctionCalledMessageHandler()

        messageHandler.addHandler(handler: OnLoadErrorMessageHandler(didReceiveMessage: { payload in
            expectation.fulfill()

            XCTAssertEqual(payload, OnLoadErrorMessageHandler.Values(error: .init(type: "failed_to_load", message: "Error message")))
        }))

        webView.addMessageHandler(messageHandler: messageHandler)

        try await webView.evaluateOnLoadError(type: "failed_to_load", message: "Error message")

        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}
