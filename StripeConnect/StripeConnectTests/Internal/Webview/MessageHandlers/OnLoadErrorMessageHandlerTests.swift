//
//  OnLoadErrorMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//
@_spi(PrivateBetaConnect) @testable import StripeConnect
import XCTest

class OnLoadErrorMessageHandlerTests: ScriptWebTestBase {

    @MainActor
    func testMessageSend() async throws {
        let messageHandler = OnSetterFunctionCalledMessageHandler(analyticsClient: MockComponentAnalyticsClient(commonFields: .mock))

        messageHandler.addHandler(handler: OnLoadErrorMessageHandler(didReceiveMessage: { payload in
            XCTAssertEqual(payload, OnLoadErrorMessageHandler.Values(error: .init(type: "failed_to_load", message: "Error message")))
        }))

        webView.addMessageHandler(messageHandler: messageHandler)

        try await webView.evaluateOnLoadError(type: "failed_to_load", message: "Error message")
    }

    @MainActor
    func testUnknownErrorTypeLogsAnalytic() async throws {
        let analyticsClient = MockComponentAnalyticsClient(commonFields: .mock)
        analyticsClient.pageViewId = "1234"

        let errorValue = OnLoadErrorMessageHandler.Values.ErrorValue(
            type: "made_up_type",
            message: "Error message"
        )

        let error = errorValue.connectEmbedError(analyticsClient: analyticsClient)

        // Type should default to api_error
        XCTAssertEqual(error.type, .apiError)
        XCTAssertEqual(error.debugDescription, "api_error: Error message")

        // Analytic logged
        XCTAssertEqual(analyticsClient.loggedEvents, [
            UnexpectedLoadErrorTypeEvent(metadata: .init(
                errorType: "made_up_type",
                pageViewId: "1234"
            )),
        ])
    }
}
