//
//  PaymentSheetImageTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 6/28/24.
//

@testable import StripePaymentSheet
@testable import StripePaymentsUI
import XCTest

final class PaymentSheetImageTests: XCTestCase {
    func testCalculateCardBrandToDisplay() {
        // Card with a known `displayBrand`
        let knownPreferredBrand = STPPaymentMethod._testCardCoBranded(brand: "visa", displayBrand: "cartes_bancaires")
        // ...should use that brand icon
        XCTAssertEqual(knownPreferredBrand.calculateCardBrandToDisplay(), .cartesBancaires)

        // Card with a unknown `displayBrand`
        let unknownPreferredBrand = STPPaymentMethod._testCardCoBranded(brand: "visa", displayBrand: "eftpos_australia")
        // ...should fall back to its `brand`
        XCTAssertEqual(unknownPreferredBrand.calculateCardBrandToDisplay(), .visa)
    }
}
