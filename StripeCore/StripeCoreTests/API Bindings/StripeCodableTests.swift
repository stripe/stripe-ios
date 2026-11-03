//
//  StripeCodableTests.swift
//  StripeCoreTests
//
//  Created by David Estes on 8/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(InternalOnlyAPI)@testable import StripeCore
import StripeCoreTestUtils
import XCTest

struct TestCodable: UnknownFieldsCodable {
    struct Nested: UnknownFieldsCodable {
        struct DeeplyNested: UnknownFieldsCodable {
            var deeplyNestedProperty: String

            var _additionalParametersStorage: NonEncodableParameters?
            var _allResponseFieldsStorage: NonEncodableParameters?
        }

        var nestedProperty: String

        var deeplyNested: DeeplyNested?

        var _additionalParametersStorage: NonEncodableParameters?
        var _allResponseFieldsStorage: NonEncodableParameters?
    }

    var topProperty: String

    var arrayProperty: [Nested]?

    var nested: Nested?

    var testEnum: TestEnum?
    var testEnums: [TestEnum]?

    var testEnumDict: [String: TestEnum]?

    enum TestEnum: String, SafeEnumCodable {
        case hello
        case hey
        case unparsable
    }

    var _additionalParametersStorage: NonEncodableParameters?
    var _allResponseFieldsStorage: NonEncodableParameters?
}

struct TestNonOptionalEnumCodable: UnknownFieldsCodable {
    var testEnum: TestEnum
    var testEnums: [TestEnum]

    enum TestEnum: String, SafeEnumCodable {
        case hello
        case hey
        case unparsable
    }

    var _additionalParametersStorage: NonEncodableParameters?
    var _allResponseFieldsStorage: NonEncodableParameters?
}

private struct RawStripeJSONDictionary: Decodable {
    let value: [AnyHashable: Any]

    init(from decoder: Decoder) throws {
        value = try decoder.stripeJSONDictionary
    }
}

private struct ResponseWithRequestID: Decodable {
    let requestID: String?

    init(from decoder: Decoder) throws {
        requestID = decoder.userInfo[StripeJSONDecoder.requestIDKey] as? String
    }
}

class StripeCodableTests: APIStubbedTestCase {
    func testDecodingFailureLogsResponseContext() throws {
        let analyticsClient = STPAnalyticsClient.sharedClient
        let previousHistory = analyticsClient._testLogHistory
        defer { analyticsClient._testLogHistory = previousHistory }
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_decoding"
        let cases: [(body: String, code: String, requestID: String?)] = [
            (#"{"top_property":"ok","array_property":[{}]}"#, "keyNotFound", "req_missing_field"),
            (#"{"top_property":"ok","array_property":[{"nested_property":{"private_response_value":true}}]}"#, "dataCorrupted", nil),
        ]
        for testCase in cases {
            // Given a successful HTTP response that cannot decode into the expected model
            analyticsClient._testLogHistory = []
            let stubDescriptor = stub(condition: { _ in true }) { _ in
                HTTPStubsResponse(
                    data: Data(testCase.body.utf8),
                    statusCode: 200,
                    headers: testCase.requestID.map { ["Request-Id": $0] }
                )
            }
            let completed = expectation(description: "Request completed")
            STPAssertTestUtil.shouldSuppressNextSTPAlert = true

            // When the Codable API client receives it
            apiClient.get(resource: "test", parameters: [:]) { (result: Result<TestCodable, Error>) in
                if case .failure(let error) = result {
                    XCTAssertTrue(error is DecodingError)
                } else {
                    XCTFail("Expected a decoding error")
                }
                completed.fulfill()
            }
            waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
            HTTPStubs.removeStub(stubDescriptor)

            // ...and one analytic contains response context, without response values
            XCTAssertFalse(STPAssertTestUtil.shouldSuppressNextSTPAlert)
            XCTAssertEqual(analyticsClient._testLogHistory.count, 1)
            let event = try XCTUnwrap(analyticsClient._testLogHistory.first)
            XCTAssertEqual(event["event"] as? String, "unexpected_error.api_response_decoding")
            XCTAssertEqual(event["error_type"] as? String, "Swift.DecodingError")
            XCTAssertEqual(event["error_code"] as? String, testCase.code)
            XCTAssertEqual(event["error_message"] as? String, "\(String(reflecting: TestCodable.self)) failed to decode")
            XCTAssertEqual(event["failed_decoding_path"] as? String, "arrayProperty.0.nestedProperty")
            XCTAssertEqual(event["request_id"] as? String, testCase.requestID)
            XCTAssertEqual(event["http_status_code"] as? Int, 200)
            XCTAssertEqual(event["response_type"] as? String, String(reflecting: TestCodable.self))
            XCTAssertEqual(event["publishable_key"] as? String, "pk_test_decoding")
            XCTAssertFalse(String(describing: event).contains("private_response_value"))
        }
    }

    func testAPIErrorWithSuccessfulStatusDoesNotLogDecodingFailure() {
        let analyticsClient = STPAnalyticsClient.sharedClient
        let previousHistory = analyticsClient._testLogHistory
        analyticsClient._testLogHistory = []
        defer { analyticsClient._testLogHistory = previousHistory }

        // An error envelope must take precedence over failure to decode the expected response.
        let result: Result<TestCodable, Error> = STPAPIClient().decodeResponse(
            data: Data(#"{"error":{"type":"api_error"}}"#.utf8),
            error: nil,
            response: HTTPURLResponse(url: URL(string: "https://api.stripe.com/v1/test")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        )

        XCTAssertThrowsError(try result.get()) { XCTAssertTrue($0 is StripeError) }
        XCTAssertTrue(analyticsClient._testLogHistory.isEmpty)
    }

    func testSuccessfulResponseExposesRequestIDToDecoder() throws {
        for requestID in ["req_123", nil] {
            // Given a successful response, with or without a request ID header
            let headers = requestID.map { ["Request-Id": $0] }
            let response = try XCTUnwrap(HTTPURLResponse(
                url: URL(string: "https://api.stripe.com/v1/test")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: headers
            ))

            // When the API client decodes the response
            let result: Result<ResponseWithRequestID, Error> = STPAPIClient().decodeResponse(
                data: Data("{}".utf8),
                error: nil,
                response: response
            )

            // Then the decoder receives the request ID when present
            XCTAssertEqual(try result.get().requestID, requestID)
        }
    }

    func testStripeJSONDictionaryReturnsCurrentObject() throws {
        let data = try JSONSerialization.data(withJSONObject: ["id": "pm_123"])

        let decoded = try StripeJSONDecoder().decode(RawStripeJSONDictionary.self, from: data)

        XCTAssertEqual(decoded.value["id"] as? String, "pm_123")
    }

    func testStripeJSONDictionaryRejectsOtherDecoders() throws {
        let data = try JSONSerialization.data(withJSONObject: ["id": "pm_123"])

        XCTAssertThrowsError(try JSONDecoder().decode(RawStripeJSONDictionary.self, from: data))
    }

    func codableTest<T: UnknownFieldsCodable>(
        codable: T,
        completion: @escaping ([String: Any], Result<T, Error>) -> Void
    ) {
        let e = expectation(description: "Request completed")
        let encodedDict = try! codable.encodeJSONDictionary()
        let encodedData = try? JSONSerialization.data(withJSONObject: encodedDict, options: [])

        let apiClient = stubbedAPIClient()
        stub { _ in
            return true
        } response: { _ in
            return HTTPStubsResponse(data: encodedData!, statusCode: 200, headers: nil)
        }

        apiClient.post(resource: "anything", object: codable) { (result: Result<T, Error>) in
            completion(encodedDict, result)
            e.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testValidEnum() {
        var codable = TestCodable(topProperty: "hello1")
        codable.additionalParameters = ["test_enum": "hey", "test_enums": ["hello", "hey"]]
        codableTest(codable: codable) { _, result in
            let resultObject = try! result.get()
            XCTAssertEqual(resultObject.testEnum, .hey)
            XCTAssertEqual(resultObject.testEnums, [.hello, .hey])
        }
    }

    func testNonOptionalValidEnum() {
        let codable = TestNonOptionalEnumCodable(testEnum: .hey, testEnums: [.hello, .hey])
        codableTest(codable: codable) { _, result in
            let resultObject = try! result.get()
            XCTAssertEqual(resultObject.testEnum, .hey)
            XCTAssertEqual(resultObject.testEnums, [.hello, .hey])
        }
    }

    func testUnknownEnum() {
        var codable = TestCodable(topProperty: "hello1")
        codable.additionalParameters = [
            "test_enum": "hellooo", "test_enums": ["hello", "helloooo"],
            "test_enum_dict": ["item1": "hello", "item2": "this_will_not_parse"],
        ]
        codableTest(codable: codable) { _, result in
            let resultObject = try! result.get()
            XCTAssertEqual(resultObject.testEnum, .unparsable)
            XCTAssertEqual(resultObject.testEnumDict!["item1"], .hello)
            XCTAssertEqual(resultObject.testEnumDict!["item2"], .unparsable)
        }
    }

    func testEmptyEnum() {
        let codable = TestCodable(topProperty: "hello1")
        codableTest(codable: codable) { _, result in
            let resultObject = try! result.get()
            XCTAssertNil(resultObject.testEnum)
        }
    }

    func testUnpopulatedFieldsAreNil() {
        let codable = TestCodable(topProperty: "hello1")
        codableTest(codable: codable) { _, result in
            let resultObject = try! result.get()
            // wrappedValues will sometimes be populated but empty. We want them to be nil.
            XCTAssertNil(resultObject.nested)
            XCTAssertNil(resultObject.nested?.deeplyNested)
        }
    }

    func testArrays() {
        var codable = TestCodable(topProperty: "hello1")
        codable.arrayProperty = [
            TestCodable.Nested(nestedProperty: "hi"), TestCodable.Nested(nestedProperty: "there"),
        ]
        codableTest(codable: codable) { _, result in
            let resultObject = try! result.get()
            XCTAssert(resultObject.arrayProperty![0].nestedProperty == "hi")
        }
    }

    func testRoundtripKnownFields() {
        var codable = TestCodable(topProperty: "hello1")
        codable.topProperty = "hello1"
        codable.nested = TestCodable.Nested(nestedProperty: "hello2")
        codable.nested!.deeplyNested = TestCodable.Nested.DeeplyNested(
            deeplyNestedProperty: "hello3"
        )
        codableTest(codable: codable) { codableDict, result in
            let resultObject = try! result.get()
            XCTAssertEqual(
                resultObject.nested!.deeplyNested!.deeplyNestedProperty,
                codable.nested!.deeplyNested!.deeplyNestedProperty
            )
            let newDictionary = try! resultObject.encodeJSONDictionary() as NSDictionary
            XCTAssert(newDictionary.isEqual(to: codableDict))
        }
    }

    func testRoundtripUnknownFields() {
        var codable = TestCodable(topProperty: "hello1")
        codable.topProperty = "hello1"
        codable.nested = TestCodable.Nested(nestedProperty: "hello2")
        codable.nested!.deeplyNested = TestCodable.Nested.DeeplyNested(
            deeplyNestedProperty: "hello3"
        )
        codable.nested?.additionalParameters = [
            "nested_property": "a_different_thing",
            "deeply_nested": [
                "hello": "world",
                "deepest": [
                    "deep":
                        ["wow": "very deep"],
                ],
            ],
        ]
        codable.additionalParameters = ["boop": "beep"]

        codableTest(codable: codable) { codableDict, result in
            let resultObject = try! result.get()
            XCTAssertEqual(
                resultObject.nested!.deeplyNested!.deeplyNestedProperty,
                codable.nested!.deeplyNested!.deeplyNestedProperty
            )
            let newDictionary = try! resultObject.encodeJSONDictionary() as NSDictionary
            XCTAssert(newDictionary.isEqual(to: codableDict))
            XCTAssertEqual(
                resultObject.nested!.nestedProperty,
                "a_different_thing"
            )
            XCTAssertEqual(
                resultObject.allResponseFields["boop"] as! String,
                "beep"
            )
            XCTAssertEqual(
                resultObject.nested!.deeplyNested!.allResponseFields["hello"] as! String,
                "world"
            )
        }
    }
}
