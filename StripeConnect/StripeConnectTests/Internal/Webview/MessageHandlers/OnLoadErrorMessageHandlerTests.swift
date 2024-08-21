//
//  OnLoadErrorMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//
@testable import StripeConnect
import XCTest

class OnLoadErrorMessageHandlerTests: ScriptMessageHandlerTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        addMessageHandler(messageHandler: OnLoadErrorMessageHandler(didReceiveMessage: { payload in
            expectation.fulfill()
            
            XCTAssertEqual(payload, OnLoadErrorMessageHandler.Values(error: .init(type: "failed_to_load", message: "Error message")))
        }))
        
        evaluateMessage(name: "onSetterFunctionCalled",
                        json: """
                        {
                            "setter": "setOnLoadError",
                            "value": {
                                "error": {
                                    "type": "failed_to_load",
                                    "message": "Error message"
                                }
                            }
                        }
                        """)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
