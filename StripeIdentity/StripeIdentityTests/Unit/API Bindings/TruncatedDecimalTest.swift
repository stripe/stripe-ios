//
//  TruncatedDecimalTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/9/22.
//

import Foundation
import XCTest
@testable import StripeIdentity

final class TruncatedDecimalTest: XCTestCase {
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()

    func testTwoDigitDecimal() throws {
        try verify(TwoDigitDecimal(float: 11111.11111), isFormattedTo: "11111.11")
        try verify(TwoDigitDecimal(float: 0.11111), isFormattedTo: "0.11")
        try verify(TwoDigitDecimal(float: 0.10111), isFormattedTo: "0.1")
        try verify(TwoDigitDecimal(float: 999.99), isFormattedTo: "999.99")
        try verify(TwoDigitDecimal(float: 999.999), isFormattedTo: "1000")
        try verify(TwoDigitDecimal(float: 999), isFormattedTo: "999")
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
        let json = try jsonEncoder.encode(container)
        guard let jsonString = String(data: json, encoding: .utf8) else {
            return XCTFail("Could not encode json to string", file: file, line: line)
        }
        XCTAssertEqual(jsonString, "{\"number\":\(string)}", file: file, line: line)

        // Verify we can decode the number
        let _ = try jsonDecoder.decode(Container<T>.self, from: json)
    }
}

private struct Container<T: TruncatedDecimal>: Codable {
    let number: T
}
