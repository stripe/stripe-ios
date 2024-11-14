//
//  ScriptMessageHandlerTests.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/8/24.
//

@testable import StripeConnect
import XCTest

class ScriptMessageHandlerTests: ScriptWebTestBase {
    @MainActor
    func testDidReceiveMessage() async throws {
        let analyticsClient = MockComponentAnalyticsClient(commonFields: .mock)
        let handler = ScriptMessageHandler<Bool>(
            name: "message",
            analyticsClient: analyticsClient
        ) { payload in
            XCTAssertTrue(payload)
        }
        webView.addMessageHandler(messageHandler: handler)

        try await webView.evaluateMessage(
            name: "message",
            json: "true"
        )

        // No analytics should be logged
        XCTAssertEqual(analyticsClient.loggedEvents.count, 0)
    }

    @MainActor
    func testDeserializationErrorLogsAnalytic() async throws {
        let analyticsClient = MockComponentAnalyticsClient(commonFields: .mock)
        let handler = ScriptMessageHandler<Bool>(
            name: "message",
            analyticsClient: analyticsClient
        ) { (_: Bool) in
            // no-op
        }
        webView.addMessageHandler(messageHandler: handler)

        try await webView.evaluateMessage(
            name: "message",
            json: """
            {
                "value": "not a bool"
            }
            """
        )

        let event = try XCTUnwrap(analyticsClient.loggedEvents.last as? DeserializeMessageErrorEvent)

        XCTAssertEqual(event.metadata.error, "NSCocoaErrorDomain:4864")
        XCTAssertNotNil(event.metadata.errorDescription)
        XCTAssertEqual(event.metadata.message, "message")
    }
}
