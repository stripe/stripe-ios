//
//  StripeCodableTest.swift
//  StripeCoreTests
//
//  Created by David Estes on 8/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest
import StripeCoreTestUtils

@_spi(STP) @testable import StripeCore
import OHHTTPStubs

struct TestCodable: StripeCodable {
    struct Nested: StripeCodable {
        struct DeeplyNested: StripeCodable {
            var deeplyNestedProperty: String

            var _additionalParametersStorage: NonEncodableParameters?
            var _allResponseFieldsStorage: NonEncodableParameters?
        }

        var nestedProperty: String
        
        @IncludeUnknownFields
        var deeplyNested: DeeplyNested?

        var _additionalParametersStorage: NonEncodableParameters?
        var _allResponseFieldsStorage: NonEncodableParameters?
    }

    var topProperty: String
    
    var arrayProperty: [Nested]?
    
    @IncludeUnknownFields
    var nested: Nested?
    
    var testEnum: TestEnum?
    var testEnums: [TestEnum]?

    enum TestEnum: String, StripeEnumCodable {
        case hello
        case hey
        case unparsable
    }
        
    var _additionalParametersStorage: NonEncodableParameters?
    var _allResponseFieldsStorage: NonEncodableParameters?
}

class StripeAPIRequestTest: APIStubbedTestCase {
    func codableTest(codable: TestCodable, completion: @escaping ([String: Any], Result<TestCodable, Error>) -> Void) {
        let e = expectation(description: "Request completed")
        let encodedDict = try! codable.encodeJSONDictionary()
        let encodedData = try? JSONSerialization.data(withJSONObject: encodedDict, options: [])

        let apiClient = stubbedAPIClient()
        stub { r in
            return true
        } response: { request in
            return HTTPStubsResponse(data: encodedData!, statusCode: 200, headers: nil)
        }

        apiClient.post(resource: "anything", object: codable) { (result: Result<TestCodable, Error>) in
            completion(encodedDict, result)
            e.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
    
    func testUnknownEnum() {
        var codable = TestCodable(topProperty: "hello1")
        codable.additionalParameters = ["test_enum": "hellooo", "test_enums": ["hello", "helloooo"]]
        codableTest(codable: codable) { encodedDict, result in
            let resultObject = try! result.get()
            XCTAssertEqual(resultObject.testEnum, .unparsable)
        }
    }
    
    func testEmptyEnum() {
        let codable = TestCodable(topProperty: "hello1")
        codableTest(codable: codable) { encodedDict, result in
            let resultObject = try! result.get()
            XCTAssertNil(resultObject.testEnum)
        }
    }
    
    
    func testUnpopulatedFieldsAreNil() {
        let codable = TestCodable(topProperty: "hello1")
        codableTest(codable: codable) { encodedDict, result in
            let resultObject = try! result.get()
            // wrappedValues will sometimes be populated but empty. We want them to be nil.
            XCTAssertNil(resultObject.nested)
            XCTAssertNil(resultObject.nested?.deeplyNested)
        }
    }
    
    func testArrays() {
        var codable = TestCodable(topProperty: "hello1")
        codable.arrayProperty = [TestCodable.Nested(nestedProperty: "hi"), TestCodable.Nested(nestedProperty: "there")]
        codableTest(codable: codable) { codableDict, result in
            let resultObject = try! result.get()
            XCTAssert(resultObject.arrayProperty![0].nestedProperty == "hi")
        }
    }
    
    func testRoundtripKnownFields() {
        var codable = TestCodable(topProperty: "hello1")
        codable.topProperty = "hello1"
        codable.nested = TestCodable.Nested(nestedProperty: "hello2")
        codable.nested!.deeplyNested = TestCodable.Nested.DeeplyNested(deeplyNestedProperty: "hello3")
        codableTest(codable: codable) { codableDict, result in
            let resultObject = try! result.get()
            XCTAssertEqual(resultObject.nested!.deeplyNested!.deeplyNestedProperty,
                           codable.nested!.deeplyNested!.deeplyNestedProperty)
            let newDictionary = try! resultObject.encodeJSONDictionary() as NSDictionary
            XCTAssert(newDictionary.isEqual(to: codableDict))
        }
    }
    
    func testRoundtripUnknownFields() {
        var codable = TestCodable(topProperty: "hello1")
        codable.topProperty = "hello1"
        codable.nested = TestCodable.Nested(nestedProperty: "hello2")
        codable.nested!.deeplyNested = TestCodable.Nested.DeeplyNested(deeplyNestedProperty: "hello3")
        codable.nested?.additionalParameters = ["nested_property": "a_different_thing",
                                                "deeply_nested": [
                                                    "hello": "world",
                                                    "deepest": ["deep":
                                                        ["wow": "very deep"]
                                                    ]
                                                ]
                                            ]
        codable.additionalParameters = ["boop": "beep"]
        
        codableTest(codable: codable) { codableDict, result in
            let resultObject = try! result.get()
            XCTAssertEqual(resultObject.nested!.deeplyNested!.deeplyNestedProperty,
                           codable.nested!.deeplyNested!.deeplyNestedProperty)
            let newDictionary = try! resultObject.encodeJSONDictionary() as NSDictionary
            XCTAssert(newDictionary.isEqual(to: codableDict))
            XCTAssertEqual(resultObject.nested!.nestedProperty,
                           "a_different_thing")
            XCTAssertEqual(resultObject.allResponseFields["boop"] as! String,
                           "beep")
            XCTAssertEqual(resultObject.nested!.deeplyNested!.allResponseFields["hello"] as! String,
                           "world")
        }
    }
}
