//
//  DebugMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//

@testable import StripeConnect
import XCTest

class DebugMessageHandlerTests: ScriptMessageHandlerTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        let debugMessage = "test message"
        
        addMessageHandler(messageHandler: DebugMessageHandler(didReceiveMessage: { payload in
            expectation.fulfill()
            XCTAssertEqual(payload, debugMessage)
        }))
        
        evaluateMessage(name: "debug",
                        json: """
                        "\(debugMessage)"
                        """)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
