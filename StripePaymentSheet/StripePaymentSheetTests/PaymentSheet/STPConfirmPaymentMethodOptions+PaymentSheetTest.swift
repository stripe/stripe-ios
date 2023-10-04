//
//  STPConfirmPaymentMethodOptions+PaymentSheetTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/4/23.
//

import Foundation
@testable import StripeApplePay
@testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
import XCTest

final class STPConfirmPaymentMethodOptions_PaymentSheetTest: XCTestCase {

    func testSetPreferredNetworks() {
        let pmo = STPConfirmPaymentMethodOptions()
        let cardNetworks: [STPCardBrand] = [.visa, .mastercard, .amex]
        let expected = ["visa", "mastercard", "american_express"]

        pmo.setPreferredNetworks(cardNetworks)

        XCTAssertEqual(pmo.cardOptions?.additionalAPIParameters["preferred_networks"] as? [String], expected)
    }

    func testSetPreferredNetworks_empty() {
        let pmo = STPConfirmPaymentMethodOptions()
        pmo.setPreferredNetworks([])
        XCTAssertNil(pmo.cardOptions?.additionalAPIParameters["preferred_networks"])
    }

    func testSetPreferredNetworks_nil() {
        let pmo = STPConfirmPaymentMethodOptions()
        pmo.setPreferredNetworks(nil)
        XCTAssertNil(pmo.cardOptions?.additionalAPIParameters["preferred_networks"])
    }
}
