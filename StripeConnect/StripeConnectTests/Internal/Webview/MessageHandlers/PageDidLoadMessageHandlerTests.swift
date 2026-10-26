//
//  PageDidLoadMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

@testable import StripeConnect
import XCTest

class PageDidLoadMessageHandlerTests: ScriptWebTestBase {
    @MainActor
    func testMessageSend() async throws {
        let pageViewId = "123"
        try await loadTrustedDocument()

        webView.addMessageHandler(messageHandler: PageDidLoadMessageHandler(
            sourcePolicy: webView.trustedMessageSourcePolicy(),
            analyticsClient: MockComponentAnalyticsClient(commonFields: .mock),
            didReceiveMessage: { payload in
                XCTAssertEqual(payload, .init(pageViewId: pageViewId))
            }
        ))

        try await webView.evaluatePageDidLoad(pageViewId: pageViewId)
    }
}
