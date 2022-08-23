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
    let dummyAddressSpecProvider: AddressSpecProvider = {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
            "CA": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .province, zip: "", zipNameType: .pin),
        ]
        return specProvider
    }()


    func testAddressFieldsMapsSpecs() throws {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
        ]
        let section = AddressSectionElement(
            title: "",
            locale: locale_enUS,
            addressSpecProvider: specProvider
        ).addressSection
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
        XCTAssertEqual(fields.map { $0.configuration.isOptional }, expected.map { $0.isOptional })
    }
    
    func testAddressFieldsWithDefaults() {
        // An address section with defaults...
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "NOACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .state, zip: "", zipNameType: .zip),
        ]
        let defaultAddress = AddressSectionElement.AddressDetails(address: .init(
            city: "San Francisco", country: "US", line1: "510 Townsend St.", line2: "Line 2", postalCode: "94102", state: "CA"
        ))
        let addressSection = AddressSectionElement(
            title: "",
            locale: locale_enUS,
            addressSpecProvider: specProvider,
            defaults: defaultAddress
        )

        XCTAssertEqual(addressSection.line1?.text, defaultAddress.address.line1)
        XCTAssertEqual(addressSection.line2?.text, defaultAddress.address.line2)
        XCTAssertEqual(addressSection.city?.text, defaultAddress.address.city)
        XCTAssertEqual(addressSection.postalCode?.text, defaultAddress.address.postalCode)
        XCTAssertEqual(addressSection.state?.text, defaultAddress.address.state)
        XCTAssertEqual(addressSection.selectedCountryCode, defaultAddress.address.country)
    }
    
    func testAddressFieldsChangeWithCountry() {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
            "ZZ": AddressSpec(format: "PZSCA", require: "CS", cityNameType: .city, stateNameType: .province, zip: "", zipNameType: .postal_code),
        ]
        let sut = AddressSectionElement(
            title: "",
            locale: locale_enUS,
            addressSpecProvider: specProvider
        )
        let section = sut.addressSection

        // Test ordering and label mapping
        typealias Expected = (label: String, isOptional: Bool)
        let expectedUSFields = [
            Expected(label: "Address line 1", isOptional: false),
            Expected(label: "Address line 2", isOptional: true),
            Expected(label: "Town or city", isOptional: true),
            Expected(label: "State", isOptional: true),
            Expected(label: "PIN", isOptional: false),
        ]
        guard let country = section.elements.first as? DropdownFieldElement else { XCTFail(); return }
        let USTextFields = section.elements.compactMap { $0 as? TextFieldElement }
        XCTAssertEqual(country.selectedIndex, 0)
        XCTAssertEqual(USTextFields.map { $0.configuration.label }, expectedUSFields.map { $0.label })
        XCTAssertEqual(USTextFields.map { $0.configuration.isOptional }, expectedUSFields.map { $0.isOptional })

        // Hack to switch the country
        country.pickerView(country.pickerView, didSelectRow: 1, inComponent: 0)
        country.didFinish(country.pickerFieldView)
        let ZZTextFields = section.elements.compactMap { $0 as? TextFieldElement }
        let expectedZZFields = [
            Expected(label: "Postal code", isOptional: true),
            Expected(label: "Province", isOptional: false),
            Expected(label: "City", isOptional: false),
            Expected(label: "Address line 1", isOptional: false),
            Expected(label: "Address line 2", isOptional: true),
        ]
        XCTAssertEqual(country.selectedIndex, 1)
        XCTAssertEqual(ZZTextFields.map { $0.configuration.label }, expectedZZFields.map { $0.label })
        XCTAssertEqual(ZZTextFields.map { $0.configuration.isOptional }, expectedZZFields.map { $0.isOptional })
    }

    func testCountries() {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin)
        ]

        // Use spec provider's country codes if no countries explicitly specified
        XCTAssertEqual(AddressSectionElement(title: "", countries: nil, addressSpecProvider: specProvider).countryCodes, ["US"])
        // Countries not in spec
        XCTAssertEqual(AddressSectionElement(title: "", countries: ["UK"], addressSpecProvider: specProvider).countryCodes, ["UK"])
        // Countries not in spec
        XCTAssertEqual(AddressSectionElement(title: "", countries: ["UK", "US"], addressSpecProvider: specProvider).countryCodes, ["UK", "US"])
    }
    
    func test_additionalFields() {
        for isOptional in [true, false] { // Test when the field is optional and when it's required
            // AddressSectionElement configured to collect a name and phone field...
            let sut = AddressSectionElement(
                addressSpecProvider: dummyAddressSpecProvider,
                defaults: .init(name: "Default name", phone: "6505551234"),
                additionalFields: .init(
                    name: .enabled(isOptional: isOptional),
                    phone: .enabled(isOptional: isOptional)
                )
            )
            // ...has a name and phone field
            guard
                let name = sut.name,
                let phone = sut.phone
            else {
                XCTFail(); return
            }
            // ...and sets the default
            XCTAssertEqual(name.text, "Default name")
            XCTAssertEqual(phone.phoneNumber?.string(as: .e164), "+16505551234")
            // ...and isOptional matches
            XCTAssertEqual(name.configuration.isOptional, isOptional)
            XCTAssertEqual(phone.textFieldElement.configuration.isOptional, isOptional)
        }
        
    }
    
    func test_additionalFields_hidden_by_default() {
        // By default, the AddressSectionElement doesn't have additional fields
        let sut = AddressSectionElement(
            addressSpecProvider: dummyAddressSpecProvider
        )
        XCTAssertNil(sut.name)
        XCTAssertNil(sut.phone)
    }
    
    func test_billing_same_as_shipping_checkbox_hidden_if_invalid_country() {
        // AddressSectionElement with 'checkbox' field enabled but with an invalid default country...
        let sut = AddressSectionElement(
            addressSpecProvider: dummyAddressSpecProvider,
            defaults: .init(address: .init(city: "San Francisco", country: "GB", line1: "510 Townsend St.", line2: nil, postalCode: "94102", state: "California")),
            additionalFields: .init(
                billingSameAsShippingCheckbox: .enabled(isOptional: false)
            )
        )
        
        // ...should not display the checkbox
        XCTAssertTrue(sut.sameAsCheckbox.view.isHidden)
    }
    
    func test_billing_same_as_shipping_checkbox_deselected_upon_edit() {
        // AddressSectionElement with 'checkbox' field enabled...
        let sut = AddressSectionElement(
            addressSpecProvider: dummyAddressSpecProvider,
            defaults: .init(address: .init(city: "San Francisco", country: "US", line1: "510 Townsend St.", line2: nil, postalCode: "94102", state: "California")),
            additionalFields: .init(
                billingSameAsShippingCheckbox: .enabled(isOptional: false)
            )
        )
        
        // ...should display the checkbox
        guard !sut.sameAsCheckbox.view.isHidden else {
            XCTFail("Missing checkbox element")
            return
        }
        XCTAssertTrue(sut.sameAsCheckbox.isSelected)
        // Editing a field...
        sut.line1?.setText("123 Foo St.")
        // ...should deselect the checkbox
        XCTAssertFalse(sut.sameAsCheckbox.isSelected)
    }
    
    func test_phone_country_updates_with_country_picker() {
        let sut = AddressSectionElement(
            addressSpecProvider: dummyAddressSpecProvider,
            additionalFields: .init(
                phone: .enabled(isOptional: false)
            )
        )
        
        // Country and phone should have same inital value
        XCTAssertEqual(sut.country.selectedIndex, sut.phone?.countryDropdownElement.selectedIndex)
        
        // Phone field should default to empty
        XCTAssertTrue(sut.phone?.textFieldElement.text.isEmpty ?? false)
        
        // Country and phone should update together when country changes and phone text is empty
        sut.country.select(index: 0)
        XCTAssertEqual(sut.country.selectedIndex, sut.phone?.countryDropdownElement.selectedIndex)
        
        // Country and phone should update together when country changes and phone text is empty
        sut.country.select(index: 1)
        XCTAssertEqual(sut.country.selectedIndex, sut.phone?.countryDropdownElement.selectedIndex)
        
        // Phone country should not change once it has text populated
        sut.phone?.textFieldElement.setText("555")
        sut.country.select(index: 0)
        XCTAssertNotEqual(sut.country.selectedIndex, sut.phone?.countryDropdownElement.selectedIndex)

    }
}
