//
//  NSDecimalNumber+StripeTest.swift
//  StripeiOS Tests
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
import XCTest

class NSDecimalNumberStripeTest: XCTestCase {
    // an incomplete list of 2 decimal point currencies
    private let twoDecimalPointCurrencies = [
        "usd",
        "dkk",
        "eur",
        "aud",
        "sek",
        "sgd",

        // Special cases:
        "cop",
        "pkr",
        "lak",
        "rsd",
        "huf",
        "lbp",
    ]

    private let noDecimalPointCurrencies = [
        "bif",
        "clp",
        "djf",
        "gnf",
        "jpy",
        "kmf",
        "krw",
        "mga",
        "pyg",
        "rwf",
        "vnd",
        "vuv",
        "xaf",
        "xof",
        "xpf",
    ]

    private let threeDecimalCurrencies = [
        "bhd",
        "jod",
        "kwd",
        "omr",
        "tnd",
    ]

    func testDecimalAmount_twoDecimal() {
        for twoDecimalPointCurrency in twoDecimalPointCurrencies {
            let decimalNumber = NSDecimalNumber.stp_decimalNumber(withAmount: 92123, currency: twoDecimalPointCurrency)
            XCTAssertEqual(decimalNumber, NSDecimalNumber(string: "921.23"))
        }
    }

    func testDecimalAmount_noDecimal() {
        for currency in noDecimalPointCurrencies {
            let decimalNumber = NSDecimalNumber.stp_decimalNumber(withAmount: 92123, currency: currency)
            XCTAssertEqual(decimalNumber, NSDecimalNumber(string: "92123"))
        }
    }

    func testDecimalAmount_LBP() {
        for currency in ["lbp", "LBP", "Lbp"] {
            for (amount, expected) in [(0, "0"), (1, "0.01"), (100, "1"), (92123, "921.23")] {
                let decimalNumber = NSDecimalNumber.stp_decimalNumber(withAmount: amount, currency: currency)
                XCTAssertEqual(decimalNumber, NSDecimalNumber(string: expected), "\(amount) \(currency)")
            }
        }
    }

    func testDecimalAmount_threeDecimal() {
        for currency in threeDecimalCurrencies {
            let decimalNumber = NSDecimalNumber.stp_decimalNumber(withAmount: 92123, currency: currency)
            XCTAssertEqual(decimalNumber, NSDecimalNumber(string: "92.123"))
        }
    }

}
