//
//  KlarnaHelperTest.swift
//  StripeiOS Tests
//
//  Created by Nick Porter on 11/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class KlarnaHelperTest: XCTestCase {

    func testAvailableCountries_eur() {
        let expected = ["AT", "FI", "DE", "NL", "BE", "ES", "IT"]
        XCTAssertEqual(expected, KlarnaHelper.availableCountries(currency: "eur"))
    }
    
    func testAvailableCountries_dkk() {
        let expected = ["DK"]
        XCTAssertEqual(expected, KlarnaHelper.availableCountries(currency: "dkk"))
    }
    
    func testAvailableCountries_nok() {
        let expected = ["NO"]
        XCTAssertEqual(expected, KlarnaHelper.availableCountries(currency: "nok"))
    }
    
    func testAvailableCountries_sek() {
        let expected = ["SE"]
        XCTAssertEqual(expected, KlarnaHelper.availableCountries(currency: "sek"))
    }
    
    func testAvailableCountries_gbp() {
        let expected = ["GB"]
        XCTAssertEqual(expected, KlarnaHelper.availableCountries(currency: "gbp"))
    }
    
    func testAvailableCountries_usd() {
        let expected = ["US"]
        XCTAssertEqual(expected, KlarnaHelper.availableCountries(currency: "usd"))
    }
    
    func testAvailableCountries_aus() {
        XCTAssertTrue(KlarnaHelper.availableCountries(currency: "aus").isEmpty)
    }
    
    func testCanBuyNow_shouldReturnTrue() {
        // https://site-admin.stripe.com/docs/payments/klarna#payment-options
        let canBuyNow = ["de_AT", "nl_BE", "de_DE", "it_IT", "nl_NL", "es_ES", "sv_SE"]
        
        for country in canBuyNow {
            XCTAssertTrue(KlarnaHelper.canBuyNow(locale: Locale(identifier: country)))
        }
    }
    
    func testCanBuyNow_shouldReturnFalse() {
        // https://site-admin.stripe.com/docs/payments/klarna#payment-options
        let canNotBuyNow = ["da_DK", "fi_FI", "fr_FR", "no_NO", "en_GB", "en_US"]
        
        for country in canNotBuyNow {
            XCTAssertFalse(KlarnaHelper.canBuyNow(locale: Locale(identifier: country)))
        }
    }

}
