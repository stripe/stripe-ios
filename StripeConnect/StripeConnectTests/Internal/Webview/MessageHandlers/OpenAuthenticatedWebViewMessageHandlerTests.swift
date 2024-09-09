//
//  OpenAuthenticatedWebViewMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

@testable import StripeConnect
import XCTest

class OpenAuthenticatedWebViewMessageHandlerTests: ScriptWebTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        let url = "https://dashboard.stripe.com"
        let id = "1234"
        webView.addMessageHandler(messageHandler: OpenAuthenticatedWebViewMessageHandler(didReceiveMessage: { payload in
            expectation.fulfill()
            XCTAssertEqual(payload, .init(url: URL(string: "https://dashboard.stripe.com")!, id: id))
        }))
        
        webView.evaluateOpenAuthenticatedWebView(url: url, id: id)
        
        waitForExpectations(timeout: TestHelpers.defaultTimeout, handler: nil)
    }
}
