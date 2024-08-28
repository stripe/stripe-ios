//
//  OnLoadErrorMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//
@testable import StripeConnect
import XCTest

class OnLoadErrorMessageHandlerTests: ScriptWebTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        webView.addMessageHandler(messageHandler: OnLoadErrorMessageHandler(didReceiveMessage: { payload in
            expectation.fulfill()
            
            XCTAssertEqual(payload, OnLoadErrorMessageHandler.Values(error: .init(type: "failed_to_load", message: "Error message")))
        }))
        
        webView.evaluateOnLoadError(type: "failed_to_load", message: "Error message")
        
        waitForExpectations(timeout: TestHelpers.defaultTimeout, handler: nil)
    }
}
