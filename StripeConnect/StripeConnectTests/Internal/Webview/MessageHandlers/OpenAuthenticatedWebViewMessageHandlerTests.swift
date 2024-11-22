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
        webView.addMessageHandler(messageHandler: OpenAuthenticatedWebViewMessageHandler(
            analyticsClient: MockComponentAnalyticsClient(commonFields: .mock),
            didReceiveMessage: { payload in
                XCTAssertEqual(payload, .init(url: URL(string: "https://dashboard.stripe.com")!, id: id))
            }
        ))

        try await webView.evaluateOpenAuthenticatedWebView(url: url, id: id)
    }
}
