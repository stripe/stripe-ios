//
//  OpenAuthenticatedWebViewMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

@testable import StripeConnect
import XCTest

class OpenAuthenticatedWebViewMessageHandlerTests: ScriptMessageHandlerTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        let url = "https://dashboard.stripe.com"
        let id = "1234"
        addMessageHandler(messageHandler: OpenAuthenticatedWebViewMessageHandler(didReceiveMessage: { payload in
            expectation.fulfill()
            XCTAssertEqual(payload, .init(url: URL(string: "https://dashboard.stripe.com")!, id: id))
        }))
        
        evaluateMessage(name: "openAuthenticatedWebView",
                        json: """
                        {"url": "\(url)", "id": "\(id)" }
                        """)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
