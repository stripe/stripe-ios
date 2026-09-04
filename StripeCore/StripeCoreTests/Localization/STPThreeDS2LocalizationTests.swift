//
//  STPThreeDS2LocalizationTests.swift
//  StripeCoreTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) @testable import StripeCore
import XCTest

final class STPThreeDS2LocalizationTests: XCTestCase {
    func testLocalizedStringUsesStripeCoreResources() {
        // Given
        STPLocalizationUtils.overrideLanguage(to: "fr")
        defer { STPLocalizationUtils.overrideLanguage(to: nil) }

        // When
        let localizedString = STPThreeDS2Localization.secureCheckout

        // Then
        XCTAssertEqual(localizedString, "Secure checkout")
    }
}
