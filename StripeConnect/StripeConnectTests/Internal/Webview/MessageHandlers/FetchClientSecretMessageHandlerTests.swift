//
//  FetchClientSecretMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//

@testable import StripeConnect
import XCTest

class FetchClientSecretMessageHandlerTests: ScriptMessageHandlerTestBase {
    
    func testMessageSend() async throws {
        let expectation = self.expectation(description: "Message received")
        let key = "key_123"
        
        addMessageReplyHandler(messageHandler: FetchClientSecretMessageHandler(didReceiveMessage: { _ in
            return key
        }), verifyResult: { result in
            XCTAssertEqual(result, key)
            expectation.fulfill()
        })
        
        try await evaluateMessageWithReply(name: "fetchClientSecret",
                                           json: "{}")
        await fulfillment(of: [expectation], timeout: 0.2)
    }
}
