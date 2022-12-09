//
//  NSDecimalNumber+StripeTest.swift
//  StripeiOS Tests
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentsUI

class NSDecimalNumberStripeTest: XCTestCase {
    func testDecimalAmount_hasDecimal() {
        // an incomplete list of 2 decimal point currencies
        let twoDecimalPointCurrencies = [
            "usd",
            "dkk",
            "eur",
            "aud",
            "sek",
            "sgd"
        ]
        
        for twoDecimalPointCurrency in twoDecimalPointCurrencies {
            let decimalNumber = NSDecimalNumber.stp_decimalNumber(withAmount: 1000, currency: twoDecimalPointCurrency)
            XCTAssertEqual(decimalNumber, NSDecimalNumber(string: "10.00"))
        }
    }

    func testDecimalAmount_noDecimal() {
        let noDecimalPointCurrencies = [
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
            "xpf"
        ]

        for currency in noDecimalPointCurrencies {
            let decimalNumber = NSDecimalNumber.stp_decimalNumber(withAmount: 1000, currency: currency)
            XCTAssertEqual(decimalNumber, NSDecimalNumber(string: "1000"))
        }
    }
    
    func testDecimalAmount_threeDecimal() {
        let threeDecimalCurrencies = [
            "bhd",
            "jod",
            "kwd",
            "omr",
            "tnd"
        ]
        
        for currency in threeDecimalCurrencies {
            let decimalNumber = NSDecimalNumber.stp_decimalNumber(withAmount: 92000, currency: currency)
            XCTAssertEqual(decimalNumber, NSDecimalNumber(string: "92"))
        }
    }
}
