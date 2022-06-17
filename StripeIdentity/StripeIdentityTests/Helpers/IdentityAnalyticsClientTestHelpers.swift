//
//  IdentityAnalyticsClientTestHelpers.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 6/13/22.
//

import Foundation
import XCTest

/*
 Some test helper methods to easily check Identity analytic payloads for
 specific property or metadata property values.
 */

func XCTAssert(analytic: [String: Any]?, hasProperty propertyName: String, withValue stringValue: String) {
    XCTAssertEqual(analytic?[propertyName] as? String, stringValue)
}

func XCTAssert(analytic: [String: Any]?, hasProperty propertyName: String, withValue intValue: Int) {
    XCTAssertEqual(analytic?[propertyName] as? Int, intValue)
}

func XCTAssert(analytic: [String: Any]?, hasProperty propertyName: String, withValue floatValue: Float) {
    XCTAssertEqual(analytic?[propertyName] as? Float, floatValue)
}

func XCTAssert(analytic: [String: Any]?, hasMetadata propertyName: String, withValue stringValue: String) {
    let metadata = analytic?["event_metadata"] as? [String: Any]
    XCTAssertEqual(metadata?[propertyName] as? String, stringValue)
}

func XCTAssert(analytic: [String: Any]?, hasMetadata propertyName: String, withValue intValue: Int) {
    let metadata = analytic?["event_metadata"] as? [String: Any]
    XCTAssertEqual(metadata?[propertyName] as? Int, intValue)
}

func XCTAssert(analytic: [String: Any]?, hasMetadata propertyName: String, withValue floatValue: Float) {
    let metadata = analytic?["event_metadata"] as? [String: Any]
    XCTAssertEqual(metadata?[propertyName] as? Float, floatValue)
}

func XCTAssert(analytic: [String: Any]?, hasMetadataError propertyName: String, withDomain domain: String, code: Int, fileName: String, file: StaticString = #filePath, line: UInt = #line) {
    let metadata = analytic?["event_metadata"] as? [String: Any]
    let error = metadata?[propertyName] as? [String: Any]
    XCTAssertEqual(error?["domain"] as? String, domain, "domain", file: file, line: line)
    XCTAssertEqual(error?["code"] as? Int, code, "code", file: file, line: line)
    XCTAssertEqual(error?["file"] as? String, fileName, "file", file: file, line: line)
}
