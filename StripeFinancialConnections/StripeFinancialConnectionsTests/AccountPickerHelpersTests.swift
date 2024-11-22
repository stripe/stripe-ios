//
//  AccountPickerHelpersTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Krisjanis Gaidis on 9/8/22.
//

@testable import StripeFinancialConnections
import XCTest

class AccountPickerHelpersTests: XCTestCase {
    func testCurrencyStringsFromUsd() {
        XCTAssertEqual(currencyString(currency: "usd", balanceAmount: 1000000), "$10,000.00")
        XCTAssertEqual(currencyString(currency: "usd", balanceAmount: 1000), "$10.00")
        XCTAssertEqual(currencyString(currency: "eur", balanceAmount: 10), "€0.10")
        XCTAssertEqual(currencyString(currency: "gbp", balanceAmount: 999), "£9.99")
        XCTAssertEqual(currencyString(currency: "jpy", balanceAmount: 543), "¥543")
        XCTAssertEqual(currencyString(currency: "krw", balanceAmount: 123456), "₩123,456")
        XCTAssertEqual(currencyString(currency: "usd", balanceAmount: 0), "$0.00")
        XCTAssertEqual(currencyString(currency: "usd", balanceAmount: -1000), "-$10.00")
        XCTAssertEqual(currencyString(currency: "usd", balanceAmount: -1000000), "-$10,000.00")
    }

    func testCurrencyStringsFromCadToUsd() {
        let currencyString = AccountPickerHelpers.currencyString(
            currency: "usd",
            balanceAmount: 1000,
            locale: Locale(identifier: "en_CA")
        )
        XCTAssertEqual(currencyString, "US$10.00")
    }

    // Helper function to hard-code a USD locale.
    private func currencyString(currency: String, balanceAmount: Int) -> String? {
        AccountPickerHelpers.currencyString(
            currency: currency,
            balanceAmount: balanceAmount,
            locale: Locale(identifier: "en_US")
        )
    }
}
