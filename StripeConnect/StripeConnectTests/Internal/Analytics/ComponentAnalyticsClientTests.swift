//
//  ComponentAnalyticsClientTests.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/7/24.
//

@testable import StripeConnect
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
import XCTest

class ComponentAnalyticsClientTests: XCTestCase {
    var mockClient: MockAnalyticsClientV2!
    var client: ComponentAnalyticsClient!

    let mockUUID = UUID(uuidString: "eb9d1d0a-2adb-4b5e-9e5c-aebd5b70810b")!

    override func setUp() {
        super.setUp()
        mockClient = .init()
        client = .init(client: mockClient, commonFields: .mock)
    }

    func testLogEvent() throws {
        client = .init(client: mockClient,
                       commonFields: .init(
                        publishableKey: "pk_123",
                        platformId: "platform_account",
                        merchantId: "merchant_account",
                        livemode: false,
                        component: .payouts,
                        componentInstance: mockUUID
                       ))
        client.log(event: MockAnalyticsEvent(metadata: .init(
            someString: "string_value",
            someInt: 42
        )))

        let payload = try XCTUnwrap(mockClient.loggedAnalyticsPayloads.first)

        XCTAssertEqual(payload["event_name"] as? String, "mock_event_name")
        XCTAssertEqual(payload["publishable_key"] as? String, "pk_123")
        XCTAssertEqual(payload["platform_id"] as? String, "platform_account")
        XCTAssertEqual(payload["merchant_id"] as? String, "merchant_account")
        XCTAssertEqual(payload["livemode"] as? Bool, false)
        XCTAssertEqual(payload["component"] as? String, "payouts")
        XCTAssertEqual(payload["component_instance"] as? String, "EB9D1D0A-2ADB-4B5E-9E5C-AEBD5B70810B")
        XCTAssertEqual(payload["publishable_key"] as? String, "pk_123")

        // Metadata should exist both in the `event_metadata` property as
        // well as in first-level
        XCTAssertEqual((payload["event_metadata"] as? NSDictionary), [
            "some_string": "string_value",
            "some_int": 42,
        ])
        XCTAssertEqual(payload["some_string"] as? String, "string_value")
        XCTAssertEqual(payload["some_int"] as? Int, 42)
    }

    func testLogComponentViewed() throws {
        let mockDate = Date.now
        client.logComponentViewed(viewedAt: mockDate)

        XCTAssertEqual(client.componentFirstViewedTime, mockDate)

        let payload = try XCTUnwrap(mockClient.loggedAnalyticsPayloads.last)
        XCTAssertEqual(payload["event_name"] as? String, "component.viewed")
    }

    func testLogComponentWebPageLoaded() throws {
        let mockDate = Date.now
        client.loadStart = mockDate.addingTimeInterval(-0.5)

        client.logComponentWebPageLoaded(loadEnd: mockDate)
        let payload = try XCTUnwrap(mockClient.loggedAnalyticsPayloads.last)
        XCTAssertEqual(payload["event_name"] as? String, "component.web.page_loaded")
        XCTAssertEqual(payload["time_to_load"] as? Double, 0.5)

        // Attempting to log the event a second time has no effect
        client.logComponentWebPageLoaded(loadEnd: .now)
        XCTAssertEqual(mockClient.loggedAnalyticsPayloads.count, 1)
    }

    func testLogComponentLoaded() throws {
        let mockDate = Date.now
        client.loadStart = mockDate.addingTimeInterval(-1.0)
        client.componentFirstViewedTime = mockDate.addingTimeInterval(-0.5)
        client.pageViewId = "1234"

        client.logComponentLoaded(loadEnd: mockDate)
        let payload = try XCTUnwrap(mockClient.loggedAnalyticsPayloads.last)
        XCTAssertEqual(payload["event_name"] as? String, "component.web.component_loaded")
        XCTAssertEqual(payload["time_to_load"] as? Double, 1.0)
        XCTAssertEqual(payload["perceived_time_to_load"] as? Double, 0.5)
        XCTAssertEqual(payload["page_view_id"] as? String, "1234")

        // Attempting to log the event a second time has no effect
        client.logComponentLoaded(loadEnd: .now)
        XCTAssertEqual(mockClient.loggedAnalyticsPayloads.count, 1)
    }

    func testLogUnexpectedLoadErrorType() throws {
        client.pageViewId = "1234"
        client.logUnexpectedLoadErrorType(type: "some_type")

        let payload = try XCTUnwrap(mockClient.loggedAnalyticsPayloads.last)
        XCTAssertEqual(payload["event_name"] as? String, "component.web.warn.unexpected_load_error_type")
        XCTAssertEqual(payload["error_type"] as? String, "some_type")
        XCTAssertEqual(payload["page_view_id"] as? String, "1234")
    }

    func testLogUnexpectedSetterEvent() throws {
        client.pageViewId = "1234"
        client.logUnexpectedSetterEvent(setter: "some_setter")

        let payload = try XCTUnwrap(mockClient.loggedAnalyticsPayloads.last)
        XCTAssertEqual(payload["event_name"] as? String, "component.web.warn.unrecognized_setter_function")
        XCTAssertEqual(payload["setter"] as? String, "some_setter")
        XCTAssertEqual(payload["page_view_id"] as? String, "1234")
    }

    func testLogDeserializeMessageErrorEvent() throws {
        client.pageViewId = "1234"
        client.logDeserializeMessageErrorEvent(message: "message", error: NSError(domain: "some_domain", code: 456, userInfo: [NSDebugDescriptionErrorKey: "error description"]))

        let payload = try XCTUnwrap(mockClient.loggedAnalyticsPayloads.last)
        XCTAssertEqual(payload["event_name"] as? String, "component.web.error.deserialize_message")
        XCTAssertEqual(payload["message"] as? String, "message")
        XCTAssertEqual(payload["error"] as? String, "some_domain:456")
        XCTAssertEqual(payload["error_description"] as? String, "error description")
        XCTAssertEqual(payload["page_view_id"] as? String, "1234")
    }

    func testLogAuthenticatedWebViewOpenedEvent() throws {
        client.pageViewId = "1234"
        client.logAuthenticatedWebViewOpenedEvent(id: "789")

        let payload = try XCTUnwrap(mockClient.loggedAnalyticsPayloads.last)
        XCTAssertEqual(payload["event_name"] as? String, "component.authenticated_web.opened")
        XCTAssertEqual(payload["authenticated_web_view_id"] as? String, "789")
        XCTAssertEqual(payload["page_view_id"] as? String, "1234")
    }

    func testLogAuthenticatedWebViewRedirected() throws {
        client.pageViewId = "1234"
        client.logAuthenticatedWebViewEventComplete(id: "789", redirected: true)

        let payload = try XCTUnwrap(mockClient.loggedAnalyticsPayloads.last)
        XCTAssertEqual(payload["event_name"] as? String, "component.authenticated_web.redirected")
        XCTAssertEqual(payload["authenticated_web_view_id"] as? String, "789")
        XCTAssertEqual(payload["page_view_id"] as? String, "1234")
    }

    func testLogAuthenticatedWebViewCanceled() throws {
        client.pageViewId = "1234"
        client.logAuthenticatedWebViewEventComplete(id: "789", redirected: false)

        let payload = try XCTUnwrap(mockClient.loggedAnalyticsPayloads.last)
        XCTAssertEqual(payload["event_name"] as? String, "component.authenticated_web.canceled")
        XCTAssertEqual(payload["authenticated_web_view_id"] as? String, "789")
        XCTAssertEqual(payload["page_view_id"] as? String, "1234")
    }

    func testLogAuthenticatedWebViewError() throws {
        client.pageViewId = "1234"
        client.logAuthenticatedWebViewEventComplete(id: "789", error: NSError(domain: "domain", code: 42))

        let payload = try XCTUnwrap(mockClient.loggedAnalyticsPayloads.last)
        XCTAssertEqual(payload["event_name"] as? String, "component.authenticated_web.error")
        XCTAssertEqual(payload["authenticated_web_view_id"] as? String, "789")
        XCTAssertEqual(payload["error"] as? String, "domain:42")
        XCTAssertEqual(payload["page_view_id"] as? String, "1234")
    }

    func testLogClientError() throws {
        client.logClientError(MockError(
            errorCode: 54,
            customPayload: ["custom_value": "value"]
        ))

        let payload = try XCTUnwrap(mockClient.loggedAnalyticsPayloads.last)
        XCTAssertEqual(payload["event_name"] as? String, "client_error")
        XCTAssertEqual(payload["error"] as? String, "MockError:54")
        XCTAssertEqual(payload["file"] as? String, "ComponentAnalyticsClientTests.swift")
        XCTAssertEqual(payload["custom_value"] as? String, "value")
    }
}

private struct MockAnalyticsEvent: ConnectAnalyticEvent {
    struct Metadata: Encodable, Equatable {
        let someString: String
        let someInt: Int
    }

    let name = "mock_event_name"
    let metadata: Metadata
}

private struct MockError: Error, AnalyticLoggableErrorV2, CustomNSError {
    static let errorDomain = "MockError"
    let errorCode: Int
    let customPayload: [String: Any]

    func analyticLoggableSerializeForLogging() -> [String: Any] {
        customPayload
    }
}
