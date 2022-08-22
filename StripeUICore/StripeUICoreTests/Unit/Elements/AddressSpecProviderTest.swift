//
//  AddressSpecProviderTest.swift
//  StripeUICoreTests
//
//  Created by Yuki Tokuhiro on 7/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import StripeUICore

class AddressSpecProviderTest: XCTestCase {
    func testLoadsJSON() throws {
        let e = expectation(description: "")
        let sut = AddressSpecProvider.shared
        sut.addressSpecs = [:]
        XCTAssertTrue(sut.addressSpecs.isEmpty)
        sut.loadAddressSpecs {
            e.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertFalse(sut.addressSpecs.isEmpty)
        
        // Sanity check some spec properties
        let us = sut.addressSpec(for: "US")
        let jp = sut.addressSpec(for: "JP")
        let gb = sut.addressSpec(for: "GB")
        
        XCTAssertEqual(us.zipNameType, .zip)
        XCTAssertEqual(jp.zipNameType, .postal_code)
        XCTAssertEqual(gb.zipNameType, .postal_code)
        
        XCTAssertEqual(us.stateNameType, .state)
        XCTAssertEqual(jp.stateNameType, .prefecture)
        XCTAssertEqual(gb.stateNameType, .province)
        
        XCTAssertEqual(us.cityNameType, .city)
        XCTAssertEqual(jp.cityNameType, .city)
        XCTAssertEqual(gb.cityNameType, .post_town)
        
        // Sanity check countries all exist
        let unknownCountries = sut.countries.filter { !Locale.isoRegionCodes.contains($0) }
        XCTAssertTrue(unknownCountries.count == 0)
        
        // Require that all countries collect at least line1 and line2
        for spec in sut.addressSpecs.values {
            XCTAssertTrue(spec.fieldOrdering.contains(.line))
        }
    }
}
