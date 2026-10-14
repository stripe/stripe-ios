//
//  PaymentSheetImageTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 6/28/24.
//

@testable @_spi(STP) import StripePayments
@testable import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsUI
import UIKit
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

    func testCalculateCardBrandToDisplay_jaywan() {
        // Card whose `brand` is Jaywan
        XCTAssertEqual(makeCard(brand: "jaywan").calculateCardBrandToDisplay(), .jaywan)
        XCTAssertEqual(makeCard(brand: "JAYWAN").card?.brand, .jaywan)

        // Card with a Jaywan `display_brand`...
        let jaywanDisplayBrand = makeCard(brand: "visa", displayBrand: "jaywan", available: ["visa", "jaywan"])
        // ...should use the display brand over the brand
        XCTAssertEqual(jaywanDisplayBrand.calculateCardBrandToDisplay(), .jaywan)

        // Card with a Jaywan preferred network...
        let jaywanPreferred = makeCard(brand: "visa", displayBrand: "visa", available: ["visa", "jaywan"], preferred: "jaywan")
        // ...should use the preferred network over the display brand
        XCTAssertEqual(jaywanPreferred.calculateCardBrandToDisplay(), .jaywan)

        // Card with a Jaywan brand and a different preferred network...
        let visaPreferred = makeCard(brand: "jaywan", available: ["visa", "jaywan"], preferred: "visa")
        // ...should use the preferred network
        XCTAssertEqual(visaPreferred.calculateCardBrandToDisplay(), .visa)
    }

    func testSavedJaywanCardImages() {
        // Given a saved card whose display brand is Jaywan
        let paymentMethod = makeCard(brand: "visa", displayBrand: "jaywan", available: ["visa", "jaywan"])
        let jaywanImage = STPImageLibrary.cardBrandImage(for: .jaywan)
        XCTAssert(jaywanImage.size != .zero)

        // Then the Jaywan icon is used for the payment option icon and the saved payment method row
        XCTAssertEqual(paymentMethod.makeIcon().pngData(), jaywanImage.pngData())
        XCTAssertEqual(paymentMethod.makeSavedPaymentMethodRowImage(iconStyle: .filled).pngData(), jaywanImage.pngData())

        // ...and the saved payment method cell image loads in both light and dark mode
        for style in [UIUserInterfaceStyle.light, .dark] {
            let cellImage = paymentMethod.makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: style, iconStyle: .filled)
            XCTAssert(cellImage.size != .zero)
        }

        // ...and the accessibility label uses the Jaywan display name
        XCTAssertEqual(paymentMethod.card?.preferredDisplayBrand, .jaywan)
        XCTAssertTrue(paymentMethod.paymentSheetAccessibilityLabel?.contains("Jaywan") ?? false)
    }

    private func makeCard(brand: String, displayBrand: String? = nil, available: [String] = [], preferred: String? = nil) -> STPPaymentMethod {
        var networks: [String: Any] = ["available": available]
        if let preferred {
            networks["preferred"] = preferred
        }
        var card: [String: Any] = [
            "last4": "4242",
            "brand": brand,
            "networks": networks,
            "exp_month": "01",
            "exp_year": "2040",
        ]
        if let displayBrand {
            card["display_brand"] = displayBrand
        }
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123card",
            "type": "card",
            "created": "12345",
            "card": card,
        ])!
    }
}
