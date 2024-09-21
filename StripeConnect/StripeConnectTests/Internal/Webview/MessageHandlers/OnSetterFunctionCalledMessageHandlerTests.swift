//
//  OnSetterFunctionCalledMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Mel Ludowise on 9/20/24.
//

@testable import StripeConnect
import XCTest

class OnSetterFunctionCalledMessageHandlerTests: ScriptWebTestBase {
    func testHandlers() {
        let expectationWithPayload = self.expectation(description: "Message with payload received")
        let expectationNoPayload = self.expectation(description: "Message without payload received")
        webView.addMessageHandler(messageHandler: OnSetterFunctionCalledMessageHandler([
            .init(setter: "onTestWithPayload", didReceiveMessage: { (payload: TestPayload) in
                XCTAssertEqual(payload, .init(param: "p", otherParam: 0))
                expectationWithPayload.fulfill()
            }),
            .init(setter: "onTestNoPayload", didReceiveMessage: {
                expectationNoPayload.fulfill()
            }),
            .init(setter: "onTestNeverCalled", didReceiveMessage: {
                XCTFail("onTestNeverCalled should not be called")
            }),
        ]))

        webView.evaluateMessage(name: "onSetterFunctionCalled", json: """
        {
            "setter": "onTestWithPayload",
            "values": {
                "param": "p",
                "otherParam": 0
            }
        }
        """)
        webView.evaluateMessage(name: "onSetterFunctionCalled", json: """
        {
            "setter": "onTestNoPayload"
        }
        """)

        waitForExpectations(timeout: TestHelpers.defaultTimeout)
    }
}

private struct TestPayload: Codable, Equatable {
    let param: String
    let otherParam: Int
}
