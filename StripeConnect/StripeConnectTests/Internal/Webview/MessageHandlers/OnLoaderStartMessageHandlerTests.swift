//
//  OnLoaderStartMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//

@testable import StripeConnect
import XCTest

class OnLoaderStartMessageHandlerTests: ScriptWebTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        webView.addMessageHandler(messageHandler: OnSetterFunctionCalledMessageHandler([
            OnLoaderStartMessageHandler { payload in
                XCTAssertEqual(payload, OnLoaderStartMessageHandler.Values(elementTagName: "onboarding"))

                expectation.fulfill()
            }
        ]))

        webView.evaluateOnLoaderStart(elementTagName: "onboarding")
        
        waitForExpectations(timeout: TestHelpers.defaultTimeout, handler: nil)
    }
}
