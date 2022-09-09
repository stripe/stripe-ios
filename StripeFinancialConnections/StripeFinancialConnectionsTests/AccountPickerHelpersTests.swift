//
//  AccountPickerHelpersTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Krisjanis Gaidis on 9/8/22.
//

import XCTest
@testable import StripeFinancialConnections

class AccountPickerHelpersTests: XCTestCase {

    func testCurrencyStrings() throws {
        XCTAssert(AccountPickerHelpers.currencyString(currency: "usd", balanceAmount: 1000000) == "$10,000.00")
        XCTAssert(AccountPickerHelpers.currencyString(currency: "usd", balanceAmount: 1000) == "$10.00")
        XCTAssert(AccountPickerHelpers.currencyString(currency: "eur", balanceAmount: 10) == "€0.10")
        XCTAssert(AccountPickerHelpers.currencyString(currency: "gbp", balanceAmount: 999) == "£9.99")
        XCTAssert(AccountPickerHelpers.currencyString(currency: "jpy", balanceAmount: 543) == "¥543")
        XCTAssert(AccountPickerHelpers.currencyString(currency: "krw", balanceAmount: 123456) == "₩123,456")
    }
}
