//
//  AddressSectionElementTest.swift
//  StripeUICoreTests
//
//  Created by Yuki Tokuhiro on 7/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import StripeUICore

class AddressSectionElementTest: XCTestCase {
    let locale_enUS = Locale(identifier: "us_EN")

    func testAddressFieldsMapsSpecs() throws {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
        ]
        let section = AddressSectionElement(
            title: "",
            locale: locale_enUS,
            addressSpecProvider: specProvider
        )
        XCTAssert(section.elements.first is DropdownFieldElement,
                  "'\(String(describing: section.elements.first.map { type(of: $0) }))' is not 'DropdownFieldElement')")
        guard let fields = Array(section.elements.dropFirst()) as? [TextFieldElement] else {
            return XCTFail("Expected `[TextFieldElement]`")
        }
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
    
    func testAddressFieldsWithDefaults() {
        // An address section with defaults...
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "NOACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .state, zip: "", zipNameType: .zip),
        ]
        let defaultAddress = AddressSectionElement.Defaults(
            city: "San Francisco", country: "US", line1: "510 Townsend St.", line2: "Line 2", postalCode: "94102", state: "CA"
        )
        let addressSection = AddressSectionElement(
            title: "",
            locale: locale_enUS,
            addressSpecProvider: specProvider,
            defaults: defaultAddress
        )

        XCTAssertEqual(addressSection.line1?.text, defaultAddress.line1)
        XCTAssertEqual(addressSection.line2?.text, defaultAddress.line2)
        XCTAssertEqual(addressSection.city?.text, defaultAddress.city)
        XCTAssertEqual(addressSection.postalCode?.text, defaultAddress.postalCode)
        XCTAssertEqual(addressSection.state?.text, defaultAddress.state)
        XCTAssertEqual(addressSection.selectedCountryCode, defaultAddress.country)
    }
    
    func testAddressFieldsChangeWithCountry() {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
            "ZZ": AddressSpec(format: "PZSCA", require: "CS", cityNameType: .city, stateNameType: .province, zip: "", zipNameType: .postal_code),
        ]
        let section = AddressSectionElement(
            title: "",
            locale: locale_enUS,
            addressSpecProvider: specProvider
        )

        // Test ordering and label mapping
        typealias Expected = (label: String, isOptional: Bool)
        let expectedUSFields = [
            Expected(label: "Address line 1", isOptional: false),
            Expected(label: "Address line 2", isOptional: true),
            Expected(label: "Town or city", isOptional: true),
            Expected(label: "State", isOptional: true),
            Expected(label: "PIN", isOptional: false),
        ]
        let USTextFields = section.elements.compactMap { $0 as? TextFieldElement }
        XCTAssertEqual(section.country.selectedIndex, 0)
        XCTAssertEqual(USTextFields.map { $0.configuration.label }, expectedUSFields.map { $0.label })
        XCTAssertEqual(USTextFields.map { $0.isOptional }, expectedUSFields.map { $0.isOptional })

        // Hack to switch the country
        section.country.pickerView(section.country.pickerView, didSelectRow: 1, inComponent: 0)
        section.country.didFinish(section.country.pickerFieldView)
        let ZZTextFields = section.elements.compactMap { $0 as? TextFieldElement }
        let expectedZZFields = [
            Expected(label: "Postal code", isOptional: true),
            Expected(label: "Province", isOptional: false),
            Expected(label: "City", isOptional: false),
            Expected(label: "Address line 1", isOptional: false),
            Expected(label: "Address line 2", isOptional: true),
        ]
        XCTAssertEqual(section.country.selectedIndex, 1)
        XCTAssertEqual(ZZTextFields.map { $0.configuration.label }, expectedZZFields.map { $0.label })
        XCTAssertEqual(ZZTextFields.map { $0.isOptional }, expectedZZFields.map { $0.isOptional })
    }
}
