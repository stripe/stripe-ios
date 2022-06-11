//
//  AnalyticsClientV2Test.swift
//  StripeCoreTests
//
//  Created by Mel Ludowise on 6/7/22.
//

import Foundation
import XCTest

@testable @_spi(STP) import StripeCore

final class AnalyticsClientV2Test: XCTestCase {
    let client = AnalyticsClientV2(
        clientId: "test_client_id",
        origin: "test_origin"
    )

    func testShouldCollectAnalytics_alwaysFalseInTest() {
        XCTAssertFalse(AnalyticsClientV2.shouldCollectAnalytics)
    }

    func testRequestHeaders() {
        let headers = client.requestHeaders
        XCTAssertEqual(headers["user-agent"]?.starts(with: "Stripe/v1 ios/"), true, String(describing: headers["user-agent"]))
        XCTAssertEqual(headers["origin"], "test_origin")
    }

    func testSerializeError() {
        let payload = AnalyticsClientV2.serialize(
            error: NSError(domain: "my_domain", code: 125, userInfo: ["foo": "bar"]),
            filePath: "/some/file/path/my_device/MyClass.swift",
            line: 786
        )

        XCTAssertEqual(payload.count, 4)
        XCTAssertEqual(payload["domain"] as? String, "my_domain")
        XCTAssertEqual(payload["code"] as? Int, 125)
        XCTAssertEqual(payload["file"] as? String, "MyClass.swift")
        XCTAssertEqual(payload["line"] as? UInt, 786)
    }

    func testCommonPayload() {
        let commonPayload = client.makeCommonPayload()

        XCTAssertEqual(commonPayload["client_id"] as? String, "test_client_id")
        XCTAssertNotNil(commonPayload["event_id"] as? String)
        XCTAssertNotNil(commonPayload["created"] as? Double)
        XCTAssertNotNil(commonPayload["os_version"] as? String)
        XCTAssertEqual(commonPayload["sdk_platform"] as? String, "ios")
        XCTAssertNotNil(commonPayload["sdk_version"] as? String)
        XCTAssertNotNil(commonPayload["device_type"] as? String)
        XCTAssertNotNil(commonPayload["app_name"] as? String)
        XCTAssertNotNil(commonPayload["app_version"] as? String)

        let platformInfo = commonPayload["platform_info"] as? [String: Any]
        XCTAssertNotNil(platformInfo?["install"] as? String)
        XCTAssertNotNil(platformInfo?["app_bundle_id"] as? String)
    }

    func testPayloadFromAnalytic() {

        let payload = client.payload(
            withEventName: "foo",
            parameters: [
                "custom_property": "test_property",
                "event_metadata": [
                    "string_property": "test_string",
                    "int_property": 156
                ]
            ]
        )

        // Ensure some common properties are present
        XCTAssertNotNil(payload["client_id"] as? String)
        XCTAssertNotNil(payload["event_id"] as? String)

        // Ensure encoded analytic is merged
        XCTAssertEqual(payload["event_name"] as? String, "foo")
        XCTAssertEqual(payload["custom_property"] as? String, "test_property")

        let metadata = payload["event_metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["string_property"] as? String, "test_string")
        XCTAssertEqual(metadata?["int_property"] as? Int, 156)
    }
}
