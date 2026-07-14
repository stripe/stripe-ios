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

    func testRequirementForCountry() {
        XCTAssertEqual(CountryTaxRequirement(country: "US"), .fullAddress)
        XCTAssertEqual(CountryTaxRequirement(country: "us"), .fullAddress)
        XCTAssertEqual(CountryTaxRequirement(country: "CA"), .stateOrProvince)
        XCTAssertEqual(CountryTaxRequirement(country: "FR"), .none)
        XCTAssertEqual(CountryTaxRequirement(country: ""), .none)
    }

    func testWidensToSatisfyRequirement() {
        XCTAssertEqual(widened(.countryAndPostal(), inCountry: "US"), .autoCompletable)
        XCTAssertEqual(widened(.countryAndPostal(), inCountry: "CA"), .countryPostalAndState)
    }

    func testNeverNarrows() {
        // No requirement -> unchanged.
        XCTAssertEqual(widened(.countryAndPostal(), inCountry: "FR"), .countryAndPostal())
        // Already at or above the requirement -> unchanged (never narrows, never a lateral move).
        XCTAssertEqual(widened(.autoCompletable, inCountry: "CA"), .autoCompletable)
        XCTAssertEqual(widened(.allWithAutocomplete, inCountry: "US"), .allWithAutocomplete)
        XCTAssertEqual(widened(.all(), inCountry: "CA"), .all())
        // .noCountry payment methods collect the country separately and are never widened.
        XCTAssertEqual(widened(.noCountry, inCountry: "US"), .noCountry)
    }

    private func widened(
        _ base: AddressSectionElement.CollectionMode,
        inCountry country: String
    ) -> AddressSectionElement.CollectionMode {
        base.widened(toSatisfy: .init(country: country))
    }
}
