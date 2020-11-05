//
//  STPFormEncoderTest.swift
//  Stripe Tests
//
//  Created by Jack Flintermann on 1/8/15.
//
//

import XCTest

@testable import Stripe

class STPTestFormEncodableObject: NSObject, STPFormEncodable {
  var additionalAPIParameters: [AnyHashable: Any] = [:]

  @objc var testProperty: String?
  @objc var testIgnoredProperty: String?
  @objc var testArrayProperty: [AnyHashable]?
  @objc var testDictionaryProperty: [AnyHashable: Any]?
  @objc var testNestedObjectProperty: STPTestFormEncodableObject?

  class func rootObjectName() -> String? {
    return "test_object"
  }

  class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [
      "testProperty": "test_property",
      "testArrayProperty": "test_array_property",
      "testDictionaryProperty": "test_dictionary_property",
      "testNestedObjectProperty": "test_nested_property",
    ]
  }
}

class STPTestNilRootObjectFormEncodableObject: STPTestFormEncodableObject {
  override class func rootObjectName() -> String? {
    return nil
  }
}

class STPFormEncoderTest: XCTestCase {
  func testStringByReplacingSnakeCaseWithCamelCase() {
    let camelCase = STPFormEncoder.stringByReplacingSnakeCase(withCamelCase: "test_1_2_34_test")
    XCTAssertEqual("test1234Test", camelCase)
  }

  // helper test method
  func encode(_ object: STPTestFormEncodableObject?) -> String? {
    let dictionary = STPFormEncoder.dictionary(forObject: object!)
    return STPFormEncoder.queryString(from: dictionary)
  }

  func testFormEncoding_emptyObject() {
    let testObject = STPTestFormEncodableObject()
    XCTAssertEqual(encode(testObject), "")
  }

  func testFormEncoding_normalObject() {
    let testObject = STPTestFormEncodableObject()
    testObject.testProperty = "success"
    testObject.testIgnoredProperty = "ignoreme"
    XCTAssertEqual(encode(testObject), "test_object[test_property]=success")
  }

  func testFormEncoding_additionalAttributes() {
    let testObject = STPTestFormEncodableObject()
    testObject.testProperty = "success"
    testObject.additionalAPIParameters = [
      "foo": "bar",
      "nested": [
        "nested_key": "nested_value"
      ],
    ]
    XCTAssertEqual(
      encode(testObject),
      "test_object[foo]=bar&test_object[nested][nested_key]=nested_value&test_object[test_property]=success"
    )
  }

  func testFormEncoding_arrayValue_empty() {
    let testObject = STPTestFormEncodableObject()
    testObject.testProperty = "success"
    testObject.testArrayProperty = []
    XCTAssertEqual(encode(testObject), "test_object[test_property]=success")
  }

  func testFormEncoding_arrayValue() {
    let testObject = STPTestFormEncodableObject()
    testObject.testProperty = "success"
    testObject.testArrayProperty = [NSNumber(value: 1), NSNumber(value: 2), NSNumber(value: 3)]
    XCTAssertEqual(
      encode(testObject),
      "test_object[test_array_property][0]=1&test_object[test_array_property][1]=2&test_object[test_array_property][2]=3&test_object[test_property]=success"
    )
  }

  func testFormEncoding_BoolAndNumbers() {
    let testObject = STPTestFormEncodableObject()
    testObject.testArrayProperty = [
      NSNumber(value: 0),
      NSNumber(value: 1),
      NSNumber(value: false),
      NSNumber(value: true),
      NSNumber(value: true),
    ]
    XCTAssertEqual(
      encode(testObject),
      """
      test_object[test_array_property][0]=0\
      &test_object[test_array_property][1]=1\
      &test_object[test_array_property][2]=false\
      &test_object[test_array_property][3]=true\
      &test_object[test_array_property][4]=true
      """)
  }

  func testFormEncoding_arrayOfEncodable() {
    let testObject = STPTestFormEncodableObject()

    let inner1 = STPTestFormEncodableObject()
    inner1.testProperty = "inner1"
    let inner2 = STPTestFormEncodableObject()
    inner2.testArrayProperty = ["inner2"]

    testObject.testArrayProperty = [inner1, inner2]

    XCTAssertEqual(
      encode(testObject),
      """
      test_object[test_array_property][0][test_property]=inner1\
      &test_object[test_array_property][1][test_array_property][0]=inner2
      """)
  }

  func testFormEncoding_dictionaryValue_empty() {
    let testObject = STPTestFormEncodableObject()
    testObject.testProperty = "success"
    testObject.testDictionaryProperty = [:]
    XCTAssertEqual(encode(testObject), "test_object[test_property]=success")
  }

  func testFormEncoding_dictionaryValue() {
    let testObject = STPTestFormEncodableObject()
    testObject.testProperty = "success"
    testObject.testDictionaryProperty = [
      "foo": "bar"
    ]
    XCTAssertEqual(
      encode(testObject),
      "test_object[test_dictionary_property][foo]=bar&test_object[test_property]=success")
  }

  func testFormEncoding_dictionaryOfEncodable() {
    let testObject = STPTestFormEncodableObject()

    let inner1 = STPTestFormEncodableObject()
    inner1.testProperty = "inner1"
    let inner2 = STPTestFormEncodableObject()
    inner2.testArrayProperty = ["inner2"]

    testObject.testDictionaryProperty = [
      "one": inner1,
      "two": inner2,
    ]

    XCTAssertEqual(
      encode(testObject),
      """
      test_object[test_dictionary_property][one][test_property]=inner1\
      &test_object[test_dictionary_property][two][test_array_property][0]=inner2
      """)
  }

  func testFormEncoding_setOfEncodable() {
    let testObject = STPTestFormEncodableObject()

    let inner = STPTestFormEncodableObject()
    inner.testProperty = "inner"

    testObject.testArrayProperty = [Set<AnyHashable>([inner])]

    XCTAssertEqual(
      encode(testObject),
      "test_object[test_array_property][0][test_property]=inner")
  }

  func testFormEncoding_nestedValue() {
    let testObject1 = STPTestFormEncodableObject()
    let testObject2 = STPTestFormEncodableObject()
    testObject2.testProperty = "nested_object"
    testObject1.testProperty = "success"
    testObject1.testNestedObjectProperty = testObject2
    XCTAssertEqual(
      encode(testObject1),
      "test_object[test_nested_property][test_property]=nested_object&test_object[test_property]=success"
    )
  }

  func testFormEncoding_nilRootObject() {
    let testObject = STPTestNilRootObjectFormEncodableObject()
    testObject.testProperty = "success"
    XCTAssertEqual(encode(testObject), "test_property=success")
  }

  func testQueryStringWithBadFields() {
    let params = [
      "foo]": "bar",
      "baz": "qux[",
      "woo;": ";hoo",
    ]
    let result = STPFormEncoder.queryString(from: params)
    XCTAssertEqual(result, "baz=qux%5B&foo%5D=bar&woo%3B=%3Bhoo")
  }

  func testQueryStringFromParameters() {
    let params =
      [
        "foo": "bar",
        "baz": [
          "qux": NSNumber(value: 1)
        ],
      ] as [String: AnyHashable]
    let result = STPFormEncoder.queryString(from: params)
    XCTAssertEqual(result, "baz[qux]=1&foo=bar")
  }

  func testPushProvisioningQueryStringFromParameters() {
    let params = [
      "ios": [
        "certificates": ["cert1", "cert2"],
        "nonce": "123mynonce",
        "nonce_signature": "sig",
      ]
    ]
    let result = STPFormEncoder.queryString(from: params)
    XCTAssertEqual(
      result,
      "ios[certificates][0]=cert1&ios[certificates][1]=cert2&ios[nonce]=123mynonce&ios[nonce_signature]=sig"
    )
  }
}
