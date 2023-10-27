//
//  LinkPopupURLParserTests.swift
//  StripePaymentSheetTests
//

import Foundation

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

class LinkPopupURLParserTests: XCTestCase {
    let testURL = URL(string: "link-popup://complete?link_status=complete&pm=eyJpZCI6InBtXzFOSjNWakx1NW8zUDE4WnB5VG9iYng2VSIsIm9iamVjdCI6InBheW1lbnRfbWV0aG9kIiwiYmlsbGluZ19kZXRhaWxzIjp7ImFkZHJlc3MiOnsiY2l0eSI6bnVsbCwiY291bnRyeSI6bnVsbCwibGluZTEiOm51bGwsImxpbmUyIjpudWxsLCJwb3N0YWxfY29kZSI6bnVsbCwic3RhdGUiOm51bGx9LCJlbWFpbCI6bnVsbCwibmFtZSI6bnVsbCwicGhvbmUiOm51bGx9LCJjYXJkIjp7ImJyYW5kIjoidmlzYSIsImNoZWNrcyI6eyJhZGRyZXNzX2xpbmUxX2NoZWNrIjpudWxsLCJhZGRyZXNzX3Bvc3RhbF9jb2RlX2NoZWNrIjpudWxsLCJjdmNfY2hlY2siOm51bGx9LCJjb3VudHJ5IjpudWxsLCJleHBfbW9udGgiOjQsImV4cF95ZWFyIjoyMDI0LCJmdW5kaW5nIjoiY3JlZGl0IiwiZ2VuZXJhdGVkX2Zyb20iOm51bGwsImxhc3Q0IjoiMDAwMCIsIm5ldHdvcmtzIjp7ImF2YWlsYWJsZSI6WyJ2aXNhIl0sInByZWZlcnJlZCI6bnVsbH0sInRocmVlX2Rfc2VjdXJlX3VzYWdlIjp7InN1cHBvcnRlZCI6dHJ1ZX0sIndhbGxldCI6eyJkeW5hbWljX2xhc3Q0IjpudWxsLCJsaW5rIjp7fSwidHlwZSI6ImxpbmsifX0sImNyZWF0ZWQiOjE2ODY3ODY4MzksImN1c3RvbWVyIjpudWxsLCJsaXZlbW9kZSI6ZmFsc2UsInR5cGUiOiJjYXJkIn0g")!

    func testBasicPMParsing() {
        let result = try! LinkPopupURLParser.result(with: testURL)
        XCTAssertEqual(result.link_status, .complete)
        XCTAssertEqual(result.pm.stripeId, "pm_1NJ3VjLu5o3P18ZpyTobbx6U")
        XCTAssertEqual(result.pm.card?.expMonth, 4)
        XCTAssertEqual(result.pm.card?.last4, "0000")
    }

    func testNoPMFails() {
        let testURL = URL(string: "link-popup://complete")!
        do {
            _ = try LinkPopupURLParser.result(with: testURL)
            XCTFail("Should not succeed")
        } catch {
            XCTAssertEqual(error as! LinkPopupURLParserError, LinkPopupURLParserError.invalidURLParams)
        }
    }
}
