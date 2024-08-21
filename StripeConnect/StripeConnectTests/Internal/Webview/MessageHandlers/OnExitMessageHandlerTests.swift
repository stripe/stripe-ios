//
//  OnExitMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//


@testable import StripeConnect
import XCTest

class OnExitMessageHandlerTests: ScriptMessageHandlerTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        
        addMessageHandler(messageHandler: OnExitMessageHandler(didReceiveMessage: {
            expectation.fulfill()
        }))
        
        evaluateMessage(name: "onSetterFunctionCalled",
                        json: """
                        {
                            "setter": "setOnExit"
                        }
                        """)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
