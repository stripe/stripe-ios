//
//  SectionElement+AddressTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 7/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class SectionElement_AddressTest: XCTestCase {
    func testAddressFieldsMapsSpecs() throws {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "XX": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
        ]
        let fields = SectionElement.addressFields(for: "XX", addressSpecProvider: specProvider)
        // Test ordering and label mapping
        typealias Expected = (label: String, isOptional: Bool)
        let expected = [
            Expected(label: "Address line 1", isOptional: false),
            Expected(label: "Address line 2", isOptional: true),
            Expected(label: "Town or city", isOptional: true),
            Expected(label: "State", isOptional: true),
            Expected(label: "PIN", isOptional: false),
        ]
        XCTAssertEqual(fields.map { $0.configuration.label }, expected.map { $0.label })
        XCTAssertEqual(fields.map { $0.isOptional }, expected.map { $0.isOptional })
    }
}
