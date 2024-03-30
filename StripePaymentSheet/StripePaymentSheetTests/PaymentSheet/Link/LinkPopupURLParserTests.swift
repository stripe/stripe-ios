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

    let testURLLogout = URL(string: "link-popup://complete?link_status=logout&session_id=abc123-123-145")!

    func testBasicPMParsing() {
        let result = try! LinkPopupURLParser.result(with: testURL)
        guard case let .complete(pm) = result else {
            XCTFail("Couldn't decode PM")
            return
        }
        XCTAssertEqual(pm.stripeId, "pm_1NJ3VjLu5o3P18ZpyTobbx6U")
        XCTAssertEqual(pm.card?.expMonth, 4)
        XCTAssertEqual(pm.card?.last4, "0000")
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

    func testLogout() {
        let result = try! LinkPopupURLParser.result(with: testURLLogout)
        guard case .logout = result else {
            XCTFail("Couldn't decode logout response")
            return
        }
    }

    func testRedactQueryStringWithKey() {
        let result = LinkPopupURLParser.redactedURLForLogging(url: testURL)
        XCTAssertEqual(result?.absoluteString, "link-popup://complete?link_status=complete&pm=%3Credacted%3E")
    }
    func testRedactQueryStringWithKey_noPm() {
        let testURLNoPM = URL(string: "link-popup://complete?link_status=complete")!
        let result = LinkPopupURLParser.redactedURLForLogging(url: testURLNoPM)
        XCTAssertEqual(result?.absoluteString, "link-popup://complete?link_status=complete")
    }
    func testRedactQueryStringWithKey_multiPm() {
        let testURLNoPM = URL(string: "link-popup://complete?link_status=complete&pm=pm1&pm=pm2")!
        let result = LinkPopupURLParser.redactedURLForLogging(url: testURLNoPM)
        XCTAssertEqual(result?.absoluteString, "link-popup://complete?link_status=complete&pm=%3Credacted%3E&pm=%3Credacted%3E")
    }
    func testRedactQueryStringWithKey_nil() {
        let result = LinkPopupURLParser.redactedURLForLogging(url: nil)
        XCTAssertNil(result)
    }
}
