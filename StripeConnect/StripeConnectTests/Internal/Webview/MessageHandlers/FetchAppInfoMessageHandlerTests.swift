//
//  FetchAppInfoMessageHandlerTests.swift
//  StripeConnect
//
//  Created by Chris Mays on 4/10/25.
//

@testable import StripeConnect
import XCTest

class FetchAppInfoMessageHandlerTests: ScriptWebTestBase {

    @MainActor
    func testMessageSend() async throws {
        let message = FetchAppInfoMessageHandler.Reply(applicationId: "com.stripe.example")
        webView.addMessageReplyHandler(messageHandler: FetchAppInfoMessageHandler(didReceiveMessage: { _ in
            return message
        }))

        try await webView.evaluateMessageWithReply(name: "fetchAppInfo",
                                                   json: "{}",
                                                   expectedResponse: message)
    }
}
