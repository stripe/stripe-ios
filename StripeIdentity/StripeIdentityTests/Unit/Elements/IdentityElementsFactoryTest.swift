//
//  IdentityElementsFactoryTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 9/28/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

// swift-format-ignore
@_spi(STP) @testable import StripeIdentity

// swift-format-ignore
@_spi(STP) @testable import StripeUICore

final class IdentityElementsFactoryTest: XCTestCase {

    let addressSpecProvider: AddressSpecProvider = {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(
                format: "ACSZP",
                require: "AZ",
                cityNameType: .post_town,
                stateNameType: .state,
                zip: "",
                zipNameType: .pin
            ),
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
        XCTAssertNil(factory.makeIDNumberSection(idNumberCountries: []))
    }

    // Verify the ID number field changes when a new country is selected
    func testIDNumberSectionCountrySelection() {
        // Note: Countries will be sorted into this order with US as the current country and english localization
        let idNumberCountries = ["US", "BR", "CA", "IT"]

        guard
            let idNumberElement = factory.makeIDNumberSection(
                idNumberCountries: idNumberCountries
            )
        else {
            return XCTFail("Expected section to be returned")
        }
        guard
            let countryDropdown = (idNumberElement.elements.first as? SectionElement)?.elements.first
                as? DropdownFieldElement
        else {
            return XCTFail("Expected a DropdownElement to be first")
        }

        // only has two supported countries: US and BR
        XCTAssertEqual(countryDropdown.items.count, 2)

        countryDropdown.didUpdate?(0)
        verifyIDTextInput(
            idNumberElement: idNumberElement,
            expectedLabel: "Last 4 of Social Security number",
            expectedType: .US_SSN_LAST4
        )
        countryDropdown.didUpdate?(1)
        verifyIDTextInput(idNumberElement: idNumberElement, expectedLabel: "Individual CPF", expectedType: .BR_CPF)
    }
}

// MARK: - Helpers

extension IdentityElementsFactoryTest {
    fileprivate func verifyIDTextInput(
        idNumberElement: IdNumberElement,
        expectedLabel: String,
        expectedType: IDNumberTextFieldConfiguration.IDNumberType?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let idElement = (idNumberElement.elements[0] as? SectionElement)?.elements.last as? TextFieldElement
        else {
            return XCTFail("Expected TextFieldElement", file: file, line: line)
        }
        guard let idNumConfig = idElement.configuration as? IDNumberTextFieldConfiguration else {
            return XCTFail(
                "Expected TextFieldElement configuration to be 'IDNumberTextFieldConfiguration' but was '\(type(of: idElement.configuration))'",
                file: file,
                line: line
            )
        }

        XCTAssertEqual(idNumConfig.label, expectedLabel, file: file, line: line)
        XCTAssertEqual(idNumConfig.type, expectedType, file: file, line: line)
    }
}
