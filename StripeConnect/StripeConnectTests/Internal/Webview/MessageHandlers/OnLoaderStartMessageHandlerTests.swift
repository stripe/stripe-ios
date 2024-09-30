//
//  OnLoaderStartMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//

@testable import StripeConnect
import XCTest

class OnLoaderStartMessageHandlerTests: ScriptWebTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")

        let messageHandler = OnSetterFunctionCalledMessageHandler()

        messageHandler.addHandler(handler: OnLoaderStartMessageHandler(didReceiveMessage: { payload in
            expectation.fulfill()

            XCTAssertEqual(payload, OnLoaderStartMessageHandler.Values(elementTagName: "onboarding"))
        }))

        webView.addMessageHandler(messageHandler: messageHandler)

        webView.evaluateOnLoaderStart(elementTagName: "onboarding")

        waitForExpectations(timeout: TestHelpers.defaultTimeout, handler: nil)
    }
}
