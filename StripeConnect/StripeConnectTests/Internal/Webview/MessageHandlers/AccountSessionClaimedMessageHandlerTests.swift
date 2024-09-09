//
//  AccountSessionClaimedMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

@testable import StripeConnect
import XCTest

class AccountSessionClaimedMessageHandlerTests: ScriptWebTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        let merchantId = "acct_1234"
        
        webView.addMessageHandler(messageHandler: AccountSessionClaimedMessageHandler(didReceiveMessage: { payload in
            expectation.fulfill()
            XCTAssertEqual(payload, .init(merchantId: merchantId))
        }))
        
        webView.evaluateAccountSessionClaimed(merchantId: merchantId)
        waitForExpectations(timeout: TestHelpers.defaultTimeout, handler: nil)
    }
}
