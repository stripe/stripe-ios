//
//  IdentityAnalyticsClientTestHelpers.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 6/13/22.
//

import Foundation
import XCTest
import StripeCoreTestUtils

/*
 Some test helper methods to easily check Identity analytic payloads for
 specific property or metadata property values.
 */

func XCTAssert<T: Equatable>(analytic: [String: Any]?, hasProperty propertyName: String, withValue value: T, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(analytic?[propertyName] as? T, value, file: file, line: line)
}

func XCTAssert<T: Equatable>(analytic: [String: Any]?, hasMetadata propertyName: String, withValue value: T, file: StaticString = #filePath, line: UInt = #line) {
    let metadata = analytic?["event_metadata"] as? [String: Any]
    XCTAssertEqual(metadata?[propertyName] as? T, value, file: file, line: line)
}

func XCTAssert(analytic: [String: Any]?, hasMetadataError propertyName: String, withDomain domain: String, code: Int, fileName: String, file: StaticString = #filePath, line: UInt = #line) {
    let metadata = analytic?["event_metadata"] as? [String: Any]
    let error = metadata?[propertyName] as? [String: Any]
    XCTAssertEqual(error?["domain"] as? String, domain, "domain", file: file, line: line)
    XCTAssertEqual(error?["code"] as? Int, code, "code", file: file, line: line)
    XCTAssertEqual(error?["file"] as? String, fileName, "file", file: file, line: line)
}
