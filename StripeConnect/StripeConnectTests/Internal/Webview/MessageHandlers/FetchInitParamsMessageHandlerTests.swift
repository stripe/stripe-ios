//
//  FetchInitParamsMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//

@testable import StripeConnect
import XCTest

class FetchInitParamsMessageHandlerTests: ScriptWebTestBase {

    @MainActor
    func testMessageSend() async throws {
        let message = FetchInitParamsMessageHandler.Reply(locale: "en", appearance: .default)
        webView.addMessageReplyHandler(messageHandler: FetchInitParamsMessageHandler(didReceiveMessage: { _ in
            return message
        }))

        try await webView.evaluateMessageWithReply(name: "fetchInitParams",
                                                   json: "{}",
                                                   expectedResponse: message)
    }
}
