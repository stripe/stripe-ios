//
//  Stripe3DS2LocalizationTests.swift
//

@_spi(InternalOnlyAPI) @testable import StripeCore
#if canImport(Stripe3DS2)
import Stripe3DS2
#else
import StripePayments
#endif
import XCTest

final class Stripe3DS2LocalizationTests: XCTestCase {
    func testLocalizedChallengeDefaults() {
        // Given the merchant uses French.
        STPLocalizationUtils.overrideLanguage(to: "fr")
        defer { STPLocalizationUtils.overrideLanguage(to: nil) }

        // When Objective-C 3DS2 code loads its defaults from Swift StripeCore.
        let navigationBar = STDSNavigationBarCustomization()

        // Then the installed package contains the translated resources.
        XCTAssertEqual(navigationBar.headerText, "Paiement sécurisé")
        XCTAssertEqual(navigationBar.buttonText, "Annuler")
    }
}
