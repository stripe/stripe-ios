//
//  OpenFinancialConnectionsMessageHandlerTests.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/18/24.
//

@testable import StripeConnect
import XCTest

class OpenFinancialConnectionsMessageHandlerTests: ScriptWebTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        webView.addMessageHandler(messageHandler: OpenFinancialConnectionsMessageHandler(analyticsClient: MockComponentAnalyticsClient(commonFields: .mock)) { payload in
            XCTAssertEqual(payload, .init(clientSecret: "secret_123", id: "1234", connectedAccountId: "acct_1234"))
            expectation.fulfill()
        })

        webView.evaluateOpenFinancialConnectionsWebView(clientSecret: "secret_123", id: "1234", connectedAccountId: "acct_1234")

        waitForExpectations(timeout: TestHelpers.defaultTimeout, handler: nil)
    }
}
