//
//  PageDidLoadMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

@testable import StripeConnect
import XCTest

class PageDidLoadMessageHandlerTests: ScriptMessageHandlerTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        
        let pageViewId = "123"
        
        addMessageHandler(messageHandler: PageDidLoadMessageHandler(didReceiveMessage: { payload in
            expectation.fulfill()
            XCTAssertEqual(payload, .init(pageViewId: pageViewId))
        }))
        
        evaluateMessage(name: "pageDidLoad",
                        json: """
                        {"pageViewId": "\(pageViewId)"}
                        """)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
