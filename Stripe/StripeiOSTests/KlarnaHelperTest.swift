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
