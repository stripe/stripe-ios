//
//  OnSetterFunctionCalledMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 9/23/24.
//

@testable import StripeConnect
import XCTest

class OnSetterFunctionCalledMessageHandlerTests: ScriptWebTestBase {
    func testDeallocation() {
        weak var weakInstance: OnSetterFunctionCalledMessageHandler?
        autoreleasepool {
            let instance = OnSetterFunctionCalledMessageHandler(analyticsClient: MockComponentAnalyticsClient(commonFields: .mock))
            weakInstance = instance
            XCTAssertNotNil(weakInstance)
        }
        XCTAssertNil(weakInstance)
    }

    @MainActor
    func testRegisteredSetterCallsDidReceive() async throws {
        let analyticsClient = MockComponentAnalyticsClient(commonFields: .mock)
        let handler = OnSetterFunctionCalledMessageHandler(analyticsClient: analyticsClient)
        webView.addMessageHandler(messageHandler: handler)

        handler.addHandler(handler: .init(setter: "setFoo", didReceiveMessage: { payload in
            XCTAssertTrue(payload)
        }))

        try await webView.evaluateMessage(
            name: "onSetterFunctionCalled",
            json: """
            {
                "setter": "setFoo",
                "value": true
            }
            """
        )

        // No analytics should be logged
        XCTAssertEqual(analyticsClient.loggedEvents.count, 0)
    }

    @MainActor
    func testUnexpectedSetterLogsAnalytic() async throws {
        let analyticsClient = MockComponentAnalyticsClient(commonFields: .mock)
        let handler = OnSetterFunctionCalledMessageHandler(analyticsClient: analyticsClient)
        webView.addMessageHandler(messageHandler: handler)

        handler.addHandler(handler: .init(setter: "setFoo", didReceiveMessage: { payload in
            XCTAssertTrue(payload)
        }))

        try await webView.evaluateMessage(
            name: "onSetterFunctionCalled",
            json: """
            {
                "setter": "madeUpSetter",
            }
            """
        )

        XCTAssertEqual(analyticsClient.loggedEvents, [
            UnrecognizedSetterEvent(metadata: .init(
                setter: "madeUpSetter",
                pageViewId: nil
            )),
        ])
    }

    @MainActor
    func testDeserializationErrorLogsAnalytic() async throws {
        let analyticsClient = MockComponentAnalyticsClient(commonFields: .mock)
        let handler = OnSetterFunctionCalledMessageHandler(analyticsClient: analyticsClient)
        webView.addMessageHandler(messageHandler: handler)

        handler.addHandler(handler: .init(setter: "setFoo", didReceiveMessage: { (_: Bool) in
            // no-op
        }))

        try await webView.evaluateMessage(
            name: "onSetterFunctionCalled",
            json: """
            {
                "setter": "setFoo",
                "value": "not a bool"
            }
            """
        )

        let event = try XCTUnwrap(analyticsClient.loggedEvents.last as? DeserializeMessageErrorEvent)

        XCTAssertEqual(event.metadata.error, "NSCocoaErrorDomain:4864")
        XCTAssertNotNil(event.metadata.errorDescription)
        XCTAssertEqual(event.metadata.message, "onSetterFunctionCalled.setFoo")
    }
}
