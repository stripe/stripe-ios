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
        // The default base collects postal for US/GB/CA. US/PR need the full address, and IN needs a
        // postal override because it isn't in the default postal list. CA/GB are already satisfied.
        XCTAssertEqual(
            CountryTaxRequirement.collectionModeOverrides(for: .countryAndPostal()),
            [
                "US": .autoCompletable,
                "PR": .autoCompletable,
                "IN": .countryAndPostal(countriesRequiringPostalCollection: ["IN"]),
            ]
        )
        // A base that already collects the full address needs no overrides.
        XCTAssertEqual(CountryTaxRequirement.collectionModeOverrides(for: .allWithAutocomplete), [:])
        XCTAssertEqual(CountryTaxRequirement.collectionModeOverrides(for: .noCountry), [:])
        // A base that collects no country's postal needs a postal override for every postal-only country.
        XCTAssertEqual(
            CountryTaxRequirement.collectionModeOverrides(for: .countryAndPostal(countriesRequiringPostalCollection: [])),
            [
                "US": .autoCompletable,
                "PR": .autoCompletable,
                "CA": .countryAndPostal(countriesRequiringPostalCollection: ["CA"]),
                "GB": .countryAndPostal(countriesRequiringPostalCollection: ["GB"]),
                "IN": .countryAndPostal(countriesRequiringPostalCollection: ["IN"]),
            ]
        )
    }
}
