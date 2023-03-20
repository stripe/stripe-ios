//
//  IdentityElementsFactoryTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 9/28/21.
//

import XCTest
@_spi(STP) @testable import StripeIdentity
@_spi(STP) @testable import StripeUICore


final class IdentityElementsFactoryTest: XCTestCase {

    let addressSpecProvider: AddressSpecProvider = {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin)
        ]
        return specProvider
    }()

    private lazy var factory = IdentityElementsFactory(
        locale: Locale(identifier: "en_US"),
        addressSpecProvider: addressSpecProvider
    )


    // MARK: - ID Number

    // Verifies that if no countries are provided, nil is returned
    func testIDNumberSectionEmptyCountries() {
        XCTAssertNil(factory.makeIDNumberSection(countryToIDNumberTypes: [:]))
    }

    // Verify the ID number field changes when a new country is selected
    func testIDNumberSectionCountrySelection() {
        // Note: Countries will be sorted into this order with US as the current country and english localization
        let countryToIDNumberTypes: [String: IdentityElementsFactory.IDNumberSpec] = [
            "US": .init(type: .US_SSN_LAST4, label: "US"),
            "BR": .init(type: .BR_CPF, label: "BR"),
            "CA": .init(type: nil, label: "CA"),
            "IT": .init(type: nil, label: "IT"),
        ]

        guard let section = factory.makeIDNumberSection(countryToIDNumberTypes: countryToIDNumberTypes) else {
            return XCTFail("Expected section to be returned")
        }
        guard let countryDropdown = section.elements.first as? DropdownFieldElement else {
            return XCTFail("Expected a DropdownElement to be first")
        }

        countryDropdown.didUpdate?(1)
        verifyIDTextInput(section: section, expectedLabel: "BR", expectedType: .BR_CPF)
        countryDropdown.didUpdate?(0)
        verifyIDTextInput(section: section, expectedLabel: "US", expectedType: .US_SSN_LAST4)
        countryDropdown.didUpdate?(3)
        verifyIDTextInput(section: section, expectedLabel: "IT", expectedType: nil)
        countryDropdown.didUpdate?(2)
        verifyIDTextInput(section: section, expectedLabel: "CA", expectedType: nil)
    }
}

// MARK: - Helpers

private extension IdentityElementsFactoryTest {
    func verifyIDTextInput(section: SectionElement,
                           expectedLabel: String,
                           expectedType: IDNumberTextFieldConfiguration.IDNumberType?,
                           file: StaticString = #filePath,
                           line: UInt = #line) {
        guard let idElement = section.elements.last as? TextFieldElement else {
            return XCTFail("Expected TextFieldElement", file: file, line: line)
        }
        guard let idNumConfig = idElement.configuration as? IDNumberTextFieldConfiguration else {
            return XCTFail("Expected TextFieldElement configuration to be 'IDNumberTextFieldConfiguration' but was '\(type(of: idElement.configuration))'", file: file, line: line)
        }

        XCTAssertEqual(idNumConfig.label, expectedLabel, file: file, line: line)
        XCTAssertEqual(idNumConfig.type, expectedType, file: file, line: line)
    }
}
