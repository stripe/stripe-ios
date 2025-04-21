//
//  OnNotificationsChangeHandlerTests.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/2/24.
//

@testable import StripeConnect
import XCTest

class OnNotificationsChangeHandlerTests: ScriptWebTestBase {
    @MainActor
    func testMessageSend() async throws {
        let expectation = self.expectation(description: "Message received")
        let messageHandler = OnSetterFunctionCalledMessageHandler(analyticsClient: MockComponentAnalyticsClient(commonFields: .mock))

        messageHandler.addHandler(handler: OnNotificationsChangeHandler(didReceiveMessage: { payload in
            expectation.fulfill()

            XCTAssertEqual(payload, OnNotificationsChangeHandler.Values(total: 11, actionRequired: 2))
        }))

        webView.addMessageHandler(messageHandler: messageHandler)

        try await webView.evaluateMessage(
            name: "onSetterFunctionCalled",
            json: """
            {
                "setter": "setOnNotificationsChange",
                "value": {
                    "total": 11,
                    "actionRequired": 2
                }
            }
            """)

        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}
