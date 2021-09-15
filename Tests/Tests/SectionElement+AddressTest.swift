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
        XCTAssertEqual(fields.map { $0.element.configuration.label }, expected.map { $0.label })
        XCTAssertEqual(fields.map { $0.element.isOptional }, expected.map { $0.isOptional })
    }
    
    func testAddressFieldsWithDefaults() {
        // An address section with defaults...
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "NOACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .state, zip: "", zipNameType: .zip),
        ]
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco", country: "US", line1: "510 Townsend St.", line2: "Line 2", postalCode: "94102", state: "CA"
        )
        let addressSection = SectionElement.makeBillingAddress(
            locale: Locale(identifier: "us_EN"),
            addressSpecProvider: specProvider,
            defaults: defaultAddress
        )
        
        // ...should update params
        let intentConfirmParams = addressSection.updateParams(params: IntentConfirmParams(type: .card))
        guard let billingDetails = intentConfirmParams?.paymentMethodParams.billingDetails?.address else {
            XCTFail()
            return
        }

        XCTAssertEqual(billingDetails.line1, defaultAddress.line1)
        XCTAssertEqual(billingDetails.line2, defaultAddress.line2)
        XCTAssertEqual(billingDetails.city, defaultAddress.city)
        XCTAssertEqual(billingDetails.postalCode, defaultAddress.postalCode)
        XCTAssertEqual(billingDetails.state, defaultAddress.state)
        XCTAssertEqual(billingDetails.country, defaultAddress.country)
    }
    
    func testAddressFieldsChangeWithCountry() {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
            "ZZ": AddressSpec(format: "PZSCA", require: "CS", cityNameType: .city, stateNameType: .province, zip: "", zipNameType: .postal_code),
        ]
        let section = SectionElement.makeBillingAddress(
            locale: Locale(identifier: "us_EN"),
            addressSpecProvider: specProvider
        )
        let countryDropdown = (section.elements.first as! PaymentMethodElementWrapper<DropdownFieldElement>).element
        
        // Test ordering and label mapping
        typealias Expected = (label: String, isOptional: Bool)
        let expectedUSFields = [
            Expected(label: "Address line 1", isOptional: false),
            Expected(label: "Address line 2", isOptional: true),
            Expected(label: "Town or city", isOptional: true),
            Expected(label: "State", isOptional: true),
            Expected(label: "PIN", isOptional: false),
        ]
        let USTextFields: [TextFieldElement] = section.elements.compactMap {
            guard let wrappedElement = $0 as? PaymentMethodElementWrapper<TextFieldElement> else {
                return nil
            }
            return wrappedElement.element
        }
        XCTAssertEqual(countryDropdown.selectedIndex, 0)
        XCTAssertEqual(USTextFields.map { $0.configuration.label }, expectedUSFields.map { $0.label })
        XCTAssertEqual(USTextFields.map { $0.isOptional }, expectedUSFields.map { $0.isOptional })
        
        // Hack to switch the country
        countryDropdown.dropdownView.selectedRow = 1
        countryDropdown.dropdownView.didTapDone()
        let ZZTextFields: [TextFieldElement] = section.elements.compactMap {
            guard let wrappedElement = $0 as? PaymentMethodElementWrapper<TextFieldElement> else {
                return nil
            }
            return wrappedElement.element
        }

        let expectedZZFields = [
            Expected(label: "Postal code", isOptional: true),
            Expected(label: "Province", isOptional: false),
            Expected(label: "City", isOptional: false),
            Expected(label: "Address line 1", isOptional: false),
            Expected(label: "Address line 2", isOptional: true),
        ]
        XCTAssertEqual(countryDropdown.selectedIndex, 1)
        XCTAssertEqual(ZZTextFields.map { $0.configuration.label }, expectedZZFields.map { $0.label })
        XCTAssertEqual(ZZTextFields.map { $0.isOptional }, expectedZZFields.map { $0.isOptional })
    }
}

