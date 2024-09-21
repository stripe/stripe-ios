//
//  OnExitMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//


@testable import StripeConnect
import XCTest

class OnExitMessageHandlerTests: ScriptWebTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")

        webView.addMessageHandler(messageHandler: OnSetterFunctionCalledMessageHandler([
            OnExitMessageHandler {
                expectation.fulfill()
            }
        ]))

        webView.evaluateSetOnExit()
        
        waitForExpectations(timeout: TestHelpers.defaultTimeout, handler: nil)
    }
}
