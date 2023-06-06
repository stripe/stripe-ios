//
//  KlarnaHelperTest.swift
//  StripeiOS Tests
//
//  Created by Nick Porter on 11/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class KlarnaHelperTest: XCTestCase {

    func testAvailableCountries_eur() {
        let expected = ["AT", "FI", "DE", "NL", "BE", "ES", "IT", "FR", "GR", "IE", "PT"]
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

    func testAvailableCountries_aud() {
        let expected = ["AU"]
        XCTAssertEqual(expected, KlarnaHelper.availableCountries(currency: "aud"))
    }

    func testAvailableCountries_cad() {
        let expected = ["CA"]
        XCTAssertEqual(expected, KlarnaHelper.availableCountries(currency: "cad"))
    }

    func testAvailableCountries_czk() {
        let expected = ["CZ"]
        XCTAssertEqual(expected, KlarnaHelper.availableCountries(currency: "czk"))
    }

    func testAvailableCountries_nzd() {
        let expected = ["NZ"]
        XCTAssertEqual(expected, KlarnaHelper.availableCountries(currency: "nzd"))
    }

    func testAvailableCountries_pln() {
        let expected = ["PL"]
        XCTAssertEqual(expected, KlarnaHelper.availableCountries(currency: "pln"))
    }

    func testAvailableCountries_chf() {
        let expected = ["CH"]
        XCTAssertEqual(expected, KlarnaHelper.availableCountries(currency: "chf"))
    }

    func testCanBuyNow_shouldReturnTrue() {
        // https://site-admin.stripe.com/docs/payments/klarna#payment-options
        let canBuyNow = ["de_AT", "nl_BE", "de_DE", "it_IT", "nl_NL", "es_ES", "sv_SE", "en_CA", "en_AU", "pl_PL", "es_PT", "de_CH", "fr_CA"]

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
