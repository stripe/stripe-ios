//
//  PageDidLoadMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

@testable import StripeConnect
import XCTest

class PageDidLoadMessageHandlerTests: ScriptWebTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        
        let pageViewId = "123"
        
        webView.addMessageHandler(messageHandler: PageDidLoadMessageHandler(didReceiveMessage: { payload in
            expectation.fulfill()
            XCTAssertEqual(payload, .init(pageViewId: pageViewId))
        }))
        
        webView.evaluatePageDidLoad(pageViewId: pageViewId)
        
        waitForExpectations(timeout: TestHelpers.defaultTimeout, handler: nil)
    }
}
