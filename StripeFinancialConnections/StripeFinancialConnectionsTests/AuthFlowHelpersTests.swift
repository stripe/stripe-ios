//
//  AuthFlowHelpersTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Krisjanis Gaidis on 10/5/22.
//

@testable import StripeFinancialConnections
import XCTest

class AuthFlowHelpersTests: XCTestCase {

    func testFormatUrlString() throws {
        XCTAssert(AuthFlowHelpers.formatUrlString(nil) == nil)
        XCTAssert(AuthFlowHelpers.formatUrlString("") == "")
        XCTAssert(AuthFlowHelpers.formatUrlString("www.") == "")
        XCTAssert(AuthFlowHelpers.formatUrlString("http://") == "")
        XCTAssert(AuthFlowHelpers.formatUrlString("https://") == "")
        XCTAssert(AuthFlowHelpers.formatUrlString("/") == "")
        XCTAssert(AuthFlowHelpers.formatUrlString("stripe.com") == "stripe.com")
        XCTAssert(AuthFlowHelpers.formatUrlString("stripe.com/") == "stripe.com")
        XCTAssert(AuthFlowHelpers.formatUrlString("www.stripe.com") == "stripe.com")
        XCTAssert(AuthFlowHelpers.formatUrlString("https://stripe.com") == "stripe.com")
        XCTAssert(AuthFlowHelpers.formatUrlString("http://stripe.com") == "stripe.com")
        XCTAssert(AuthFlowHelpers.formatUrlString("http://www.stripe.com") == "stripe.com")
        XCTAssert(AuthFlowHelpers.formatUrlString("https://www.stripe.com") == "stripe.com")
        XCTAssert(AuthFlowHelpers.formatUrlString("https://www.stripe.com/") == "stripe.com")
        XCTAssert(AuthFlowHelpers.formatUrlString("https://www.wow.stripe.com/") == "wow.stripe.com")
    }
}
