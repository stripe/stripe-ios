//
//  TruncatedDecimalTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/9/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

// swift-format-ignore
@_spi(STP) @testable import StripeCore

@testable import StripeIdentity

final class TruncatedDecimalTest: XCTestCase {
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()

    func testFourDigitDecimal() throws {
        try verify(FourDecimalFloat(11111.11111), isFormattedTo: "11111.1113")
        try verify(FourDecimalFloat(0.11111), isFormattedTo: "0.1111")
        try verify(FourDecimalFloat(0.10111), isFormattedTo: "0.1011")
        try verify(FourDecimalFloat(999.99), isFormattedTo: "999.9900")
        try verify(FourDecimalFloat(999.999), isFormattedTo: "999.9990")
        try verify(FourDecimalFloat(999), isFormattedTo: "999.0000")

        // Regression testing IDPROD-3304
        try verify(FourDecimalFloat(0.8090820312499999744), isFormattedTo: "0.8091")
    }
}

extension TruncatedDecimalTest {
    fileprivate func verify<T: TruncatedDecimal>(
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
        XCTAssertEqual(
            queryString,
            "number=\(string)",
            "encodeJSONDictionary",
            file: file,
            line: line
        )

        // Verify we can decode the number
        guard let jsonDataToDecode = "{\"number\":\(string)}".data(using: .utf8) else {
            return XCTFail("Could not encode string to json", file: file, line: line)
        }
        _ = try jsonDecoder.decode(Container<T>.self, from: jsonDataToDecode)
    }
}

private struct Container<T: TruncatedDecimal>: UnknownFieldsCodable {
    var _additionalParametersStorage: NonEncodableParameters?

    var _allResponseFieldsStorage: NonEncodableParameters?

    let number: T
}
