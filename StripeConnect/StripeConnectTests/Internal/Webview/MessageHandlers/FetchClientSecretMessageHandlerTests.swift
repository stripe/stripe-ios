//
//  FetchClientSecretMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//

@testable import StripeConnect
import XCTest

class FetchClientSecretMessageHandlerTests: ScriptWebTestBase {

    @MainActor
    func testMessageSend() async throws {
        let key = "key_123"

        let messageHandler = FetchClientSecretMessageHandler(didReceiveMessage: { _ in
            return key
        })

        webView.addMessageReplyHandler(messageHandler: messageHandler)

        try await webView.evaluateMessageWithReply(name: "fetchClientSecret",
                                                   json: "{}",
                                                   expectedResponse: key)
    }
}
