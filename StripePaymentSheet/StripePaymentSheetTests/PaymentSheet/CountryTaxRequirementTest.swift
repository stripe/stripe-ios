//
//  CountryTaxRequirementTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 7/13/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripeUICore

final class CountryTaxRequirementTest: XCTestCase {

    func testCollectionModeOverrides() {
        // A base that satisfies nothing gets an override for every country with a requirement.
        XCTAssertEqual(
            CountryTaxRequirement.collectionModeOverrides(for: .countryAndPostal()),
            ["US": .autoCompletable, "CA": .countryPostalAndState]
        )
        // A base that already collects the full address needs no overrides.
        XCTAssertEqual(CountryTaxRequirement.collectionModeOverrides(for: .allWithAutocomplete), [:])
        XCTAssertEqual(CountryTaxRequirement.collectionModeOverrides(for: .noCountry), [:])
        // A base collecting state but not the full address only needs the US override.
        XCTAssertEqual(
            CountryTaxRequirement.collectionModeOverrides(for: .countryPostalAndState),
            ["US": .autoCompletable]
        )
    }
}
