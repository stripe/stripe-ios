//
//  ConsumerPaymentDetailsEncodingTests.swift
//  StripePaymentSheetTests
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentSheet
import XCTest

class ConsumerPaymentDetailsEncodingTests: XCTestCase {

    // Verifies that encoding a ParsedEnum<DetailsType> for any known case
    // produces the same string as the enum's rawValue.
    //
    // This matters because ParsedEnum always encodes via its rawValue — if the
    // inner enum's rawValue ever diverges from what the API expects, this test
    // will catch it.
    func test_parsedEnumEncodingMatchesUnderlyingRawValue() throws {
        for detailsType in ConsumerPaymentDetails.DetailsType.allCases {
            let parsed = ParsedEnum(detailsType)
            let encodedData = try JSONEncoder().encode(parsed)
            let encodedString = try JSONDecoder().decode(String.self, from: encodedData)
            XCTAssertEqual(
                encodedString,
                detailsType.rawValue,
                "ParsedEnum<DetailsType> encoding should match rawValue for .\(detailsType)"
            )
        }
    }
}
