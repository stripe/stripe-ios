//
//  OpenAuthenticatedWebViewMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

@testable import StripeConnect
import XCTest

class OpenAuthenticatedWebViewMessageHandlerTests: ScriptWebTestBase {
    @MainActor
    func testMessageSend() async throws {
        let url = "https://dashboard.stripe.com"
        let id = "1234"
        webView.addMessageReplyHandler(messageHandler: OpenAuthenticatedWebViewMessageHandler(didReceiveMessage: { payload in
            XCTAssertEqual(payload, .init(url: URL(string: "https://dashboard.stripe.com")!, id: id))
            return .init(url: URL(string: "stripe-connect://someurl"))
        }))

        try await webView.evaluateMessageWithReply(
            name: "openAuthenticatedWebView",
            json: "{\"url\": \"\(url)\", \"id\": \"\(id)\" }",
            expectedResponse: OpenAuthenticatedWebViewMessageHandler.Response(url: URL(string: "stripe-connect://someurl")))
    }
}
