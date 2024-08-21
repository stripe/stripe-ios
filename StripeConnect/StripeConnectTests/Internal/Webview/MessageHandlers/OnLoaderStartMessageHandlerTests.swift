//
//  OnLoaderStartMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//

@testable import StripeConnect
import XCTest

class OnLoaderStartMessageHandlerTests: ScriptMessageHandlerTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        addMessageHandler(messageHandler: OnLoaderStartMessageHandler(didReceiveMessage: { payload in
            expectation.fulfill()
            
            XCTAssertEqual(payload, OnLoaderStartMessageHandler.Values(elementTagName: "onboarding"))
        }))
        
        evaluateMessage(name: "onSetterFunctionCalled",
                        json: """
                        {
                            "setter": "setOnLoaderStart",
                            "value": {
                                "elementTagName": "onboarding"
                            }
                        }
                        """)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
