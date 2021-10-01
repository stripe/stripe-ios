//
//  Locale+StripeUICoreTests.swift
//  StripeUICoreTests
//
//  Created by Mel Ludowise on 9/28/21.
//

import XCTest
@_spi(STP) @testable import StripeUICore

final class LocaleStripeUICoreTests: XCTestCase {
    // English, United States
    let localeEN_US = Locale(identifier: "en_US")

    // Spanish, El Salvador
    let localeES_SV = Locale(identifier: "es_SV")

    let regions = [
        "IT", // Italy         (Italia)
        "CA", // Canada        (Canadá)
        "US", // United States (Estados Unidos)
        "DZ", // Algeria       (Argelia)
        "SV", // El Salvador   (El Salvador)
    ]

    // Sort countries by English localization
    func testSortRegionsEnglish() {
        let sorted = localeEN_US.sortedByTheirLocalizedNames(
            regions,
            thisRegionFirst: false
        )
        XCTAssertEqual(sorted, ["DZ", "CA", "SV", "IT", "US"])
    }

    // Sort countries by Spanish localization
    func testSortRegionsSpanish() {
        let sorted = localeES_SV.sortedByTheirLocalizedNames(
            regions,
            thisRegionFirst: false
        )
        XCTAssertEqual(sorted, ["DZ", "CA", "SV", "US", "IT"])
    }

    // Sort countries by English localization, with current country (US) first
    func testSortCountriesUSFirst() {
        let sorted = localeEN_US.sortedByTheirLocalizedNames(
            regions,
            thisRegionFirst: true
        )
        XCTAssertEqual(sorted, ["US", "DZ", "CA", "SV", "IT"])
    }

    // Sort countries by English localization, with current country (SV) first
    func testSortCountriesSVFirst() {
        let sorted = localeES_SV.sortedByTheirLocalizedNames(
            regions,
            thisRegionFirst: true
        )
        XCTAssertEqual(sorted, ["SV", "DZ", "CA", "US", "IT"])
    }

    // Ask for current country to be first when the list of countries doesn't contain it
    func testSortCountriesMissingCurrent() {
        var missingUS = regions
        missingUS.removeAll(where: { $0 == "US" })
        let sorted = localeEN_US.sortedByTheirLocalizedNames(
            missingUS,
            thisRegionFirst: true
        )
        XCTAssertEqual(sorted, ["DZ", "CA", "SV", "IT"])
    }
}
