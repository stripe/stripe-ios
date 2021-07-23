//
//  AddressSpecProviderTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 7/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

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
        XCTAssertEqual(us.zipNameType, .zip)
        XCTAssertEqual(jp.zipNameType, .postal_code)
        
        XCTAssertEqual(us.stateNameType, .state)
        XCTAssertEqual(jp.stateNameType, .prefecture)
        
        XCTAssertEqual(us.cityNameType, .city)
        XCTAssertEqual(jp.cityNameType, .city)
        
        // Sanity check countries all exist
        let unknownCountries = sut.countries.filter { !Locale.isoRegionCodes.contains($0) }
        XCTAssertTrue(unknownCountries.count == 0)
    }
}
