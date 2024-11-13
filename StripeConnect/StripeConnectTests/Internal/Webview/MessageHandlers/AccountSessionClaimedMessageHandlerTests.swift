//
//  AccountSessionClaimedMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

@testable import StripeConnect
import XCTest

class AccountSessionClaimedMessageHandlerTests: ScriptWebTestBase {
    @MainActor
    func testMessageSend() async throws {
        let merchantId = "acct_1234"

        webView.addMessageHandler(messageHandler: AccountSessionClaimedMessageHandler(
            analyticsClient: MockComponentAnalyticsClient(commonFields: .mock),
            didReceiveMessage: { payload in
                XCTAssertEqual(payload, .init(merchantId: merchantId))
            }
        ))

        try await webView.evaluateAccountSessionClaimed(merchantId: merchantId)
    }
}
