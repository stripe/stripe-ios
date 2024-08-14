//
//  AccountSessionClaimedMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

@testable import StripeConnect
import XCTest

class AccountSessionClaimedMessageHandlerTests: ScriptMessageHandlerTestBase {
    func testMessageSend() {
        let expectation = self.expectation(description: "Message received")
        let merchantId = "acct_1234"
        
        addMessageHandler(messageHandler: AccountSessionClaimedMessageHandler(didReceiveMessage: { payload in
            expectation.fulfill()
            XCTAssertEqual(payload, .init(merchantId: merchantId))
        }))
        
        evaluateMessage(name: "accountSessionClaimed",
                        json: """
                        {"merchantId": "\(merchantId)"}
                        """)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
