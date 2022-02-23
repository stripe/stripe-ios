//
//  TruncatedDecimalTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/9/22.
//

import Foundation
import XCTest
@_spi(STP) @testable import StripeCore
@testable import StripeIdentity

final class TruncatedDecimalTest: XCTestCase {
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()

    func testTwoDigitDecimal() throws {
        try verify(TwoDecimalFloat(11111.11111), isFormattedTo: "11111.11")
        try verify(TwoDecimalFloat(0.11111), isFormattedTo: "0.11")
        try verify(TwoDecimalFloat(0.10111), isFormattedTo: "0.10")
        try verify(TwoDecimalFloat(999.99), isFormattedTo: "999.99")
        try verify(TwoDecimalFloat(999.999), isFormattedTo: "1000.00")
        try verify(TwoDecimalFloat(999), isFormattedTo: "999.00")

        // Regression testing IDPROD-3304
        try verify(TwoDecimalFloat(0.8090820312499999744), isFormattedTo: "0.81")
    }
}

private extension TruncatedDecimalTest {
    func verify<T: TruncatedDecimal>(
        _ truncatedDecimal: T,
        isFormattedTo string: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        // Wrap in a container so we can test that the encoded value is not
        // wrapped in quotations or represented as a nested container
        let container = Container(number: truncatedDecimal)

        let jsonDict = try container.encodeJSONDictionary()
        let queryString = URLEncoder.queryString(from: jsonDict)
        XCTAssertEqual(queryString, "number=\(string)", "encodeJSONDictionary", file: file, line: line)

        // Verify we can decode the number
        guard let jsonDataToDecode = "{\"number\":\(string)}".data(using: .utf8) else {
            return XCTFail("Could not encode string to json", file: file, line: line)
        }
        let _ = try jsonDecoder.decode(Container<T>.self, from: jsonDataToDecode)
    }
}

private struct Container<T: TruncatedDecimal>: StripeCodable {
    var _additionalParametersStorage: NonEncodableParameters?

    var _allResponseFieldsStorage: NonEncodableParameters?

    let number: T
}
