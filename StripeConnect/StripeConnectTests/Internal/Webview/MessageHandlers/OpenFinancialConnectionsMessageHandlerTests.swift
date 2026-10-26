//
//  OpenFinancialConnectionsMessageHandlerTests.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/18/24.
//

@testable import StripeConnect
import XCTest

class OpenFinancialConnectionsMessageHandlerTests: ScriptWebTestBase {
    func testMessageSend() async throws {
        let expectation = self.expectation(description: "Message received")
        try await loadTrustedDocument()
        webView.addMessageHandler(messageHandler: OpenFinancialConnectionsMessageHandler(sourcePolicy: webView.trustedMessageSourcePolicy(), analyticsClient: MockComponentAnalyticsClient(commonFields: .mock)) { payload in
            XCTAssertEqual(payload, .init(clientSecret: "secret_123", id: "1234", connectedAccountId: "acct_1234"))
            expectation.fulfill()
        })

        webView.evaluateOpenFinancialConnectionsWebView(clientSecret: "secret_123", id: "1234", connectedAccountId: "acct_1234")

        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}
