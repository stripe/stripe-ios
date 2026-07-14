//
//  AddressSectionElementTest.swift
//  StripeUICoreTests
//
//  Created by Yuki Tokuhiro on 7/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripeUICore
import XCTest

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
        XCTAssertEqual(addressSection.state?.rawData, defaultAddress.address.state)
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
        country.didFinish(country.pickerFieldView, shouldAutoAdvance: true)
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

    func testCountryPostalAndStateMode() {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .state, zip: "", zipNameType: .zip),
            "FR": AddressSpec(format: "ACZ", require: "ACZ", cityNameType: .city, stateNameType: .province, zip: "", zipNameType: .postal_code),
        ]
        let sut = AddressSectionElement(
            title: "",
            countries: ["US", "FR"],
            locale: locale_enUS,
            addressSpecProvider: specProvider,
            collectionMode: .countryPostalAndState
        )

        // A country with a state in its spec: state + postal only, no street/city.
        sut.selectedCountryCode = "US"
        XCTAssertNotNil(sut.state)
        XCTAssertNotNil(sut.postalCode)
        XCTAssertNil(sut.line1)
        XCTAssertNil(sut.line2)
        XCTAssertNil(sut.city)

        // A country with no state in its spec: postal only.
        sut.selectedCountryCode = "FR"
        XCTAssertNil(sut.state)
        XCTAssertNotNil(sut.postalCode)
        XCTAssertNil(sut.line1)
        XCTAssertNil(sut.city)
    }

    func testCountryCollectionModeOverrides() throws {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .state, zip: "", zipNameType: .zip),
            "CA": AddressSpec(format: "ACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .province, zip: "", zipNameType: .postal_code),
            "FR": AddressSpec(format: "ACZ", require: "ACZ", cityNameType: .city, stateNameType: .province, zip: "", zipNameType: .postal_code),
        ]
        let sut = AddressSectionElement(
            title: "",
            countries: ["US", "CA", "FR"],
            locale: locale_enUS,
            addressSpecProvider: specProvider,
            defaults: .init(address: .init(country: "US")),
            collectionMode: .countryAndPostal(),
            countryCollectionModeOverrides: [
                "US": .autoCompletable,
                "CA": .countryPostalAndState,
            ]
        )

        // The override for the initial country is applied at init.
        XCTAssertEqual(sut.collectionMode, .autoCompletable)

        // Selecting a country with a different override switches to it.
        sut.country.select(index: try XCTUnwrap(sut.countryCodes.firstIndex(of: "CA")))
        XCTAssertEqual(sut.collectionMode, .countryPostalAndState)

        // Selecting a country with no override falls back to the base mode.
        sut.country.select(index: try XCTUnwrap(sut.countryCodes.firstIndex(of: "FR")))
        XCTAssertEqual(sut.collectionMode, .countryAndPostal())

        // And selecting an overridden country again re-applies its override, even if the
        // collection mode was changed externally in the meantime (e.g. after autocomplete).
        sut.country.select(index: try XCTUnwrap(sut.countryCodes.firstIndex(of: "US")))
        sut.collectionMode = .allWithAutocomplete
        sut.country.select(index: try XCTUnwrap(sut.countryCodes.firstIndex(of: "CA")))
        XCTAssertEqual(sut.collectionMode, .countryPostalAndState)

        // Without overrides, country changes never touch an externally-set collection mode.
        let noOverrides = AddressSectionElement(
            title: "",
            countries: ["US", "FR"],
            locale: locale_enUS,
            addressSpecProvider: specProvider,
            collectionMode: .autoCompletable
        )
        noOverrides.collectionMode = .allWithAutocomplete
        noOverrides.country.select(index: try XCTUnwrap(noOverrides.countryCodes.firstIndex(of: "FR")))
        XCTAssertEqual(noOverrides.collectionMode, .allWithAutocomplete)
    }

    func testCountries() {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
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

    func test_state_dropdown_starts_empty_validation() {
        // Create a spec where State is required and has dropdown values
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(
                format: "ACS", // collect Address, City, State
                require: "AS", // Address & State required
                cityNameType: .city,
                stateNameType: .state,
                zip: nil,
                zipNameType: .zip,
                subKeys: ["CA", "NY"],
                subLabels: ["California", "New York"]
            ),
        ]

        let sut = AddressSectionElement(
            title: "",
            locale: locale_enUS,
            addressSpecProvider: specProvider
        )

        guard let stateDropdown = sut.state as? DropdownFieldElement else {
            return XCTFail("Expected state element to be DropdownFieldElement")
        }

        // Placeholder should be selected initially, making the field invalid
        XCTAssertEqual(stateDropdown.selectedIndex, 0)
        XCTAssertFalse(stateDropdown.validationState.isValid)

        // Select the first actual state (index 1) and check that validation becomes valid
        stateDropdown.select(index: 1, shouldAutoAdvance: false)
        XCTAssertTrue(stateDropdown.validationState.isValid)
        XCTAssertEqual(sut.addressDetails.address.state, "CA")
    }

    func testJapanAddressIncludesCityField() {
        // Japan addresses are:
        // - Postcode
        // - Prefecture (state)
        // - Municipality
        // - Ward/chome
        // - Banchi/go (line1)
        // - Building name (line2)
        //
        // Users are expected to enter municipality and ward/chome into the city field,
        // so it should be required.
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "JP": AddressSpec(
                format: "〒%Z%n%S%C%n%A%n%O%n%N",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .prefecture,
                zip: "\\d{3}-?\\d{4}",
                zipNameType: .zip
            ),
        ]
        let sut = AddressSectionElement(
            title: "",
            countries: ["JP"],
            locale: locale_enUS,
            addressSpecProvider: specProvider
        )
        let section = sut.addressSection

        // Verify that the city field exists
        XCTAssertNotNil(sut.city, "Japan address should include a city field")

        // Verify the field ordering contains .city after .state
        let spec = specProvider.addressSpecs["JP"]!
        XCTAssertTrue(spec.fieldOrdering.contains(.city), "JP field ordering should contain .city")
        XCTAssertTrue(spec.requiredFields.contains(.city), "JP required fields should contain .city")
        if let stateIndex = spec.fieldOrdering.firstIndex(of: .state),
           let cityIndex = spec.fieldOrdering.firstIndex(of: .city) {
            XCTAssertTrue(cityIndex > stateIndex, "City should come after state/prefecture in JP address")
        } else {
            XCTFail("Both .state and .city should be in JP field ordering")
        }

        // Verify city field is not optional (it's required)
        let textFields = section.elements.compactMap { $0 as? TextFieldElement }
        let cityField = textFields.first { $0.configuration.label == "City" }
        XCTAssertNotNil(cityField, "City text field should be present in JP address form")
        XCTAssertFalse(cityField?.configuration.isOptional ?? true, "City should be required for JP addresses")
    }

    func testJapanAddressSpecFromJSON() {
        // Verify the actual JSON data includes city for JP by loading the real spec provider
        let specProvider = AddressSpecProvider()
        let expectation = expectation(description: "Address specs loaded")
        specProvider.loadAddressSpecs {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        guard let jpSpec = specProvider.addressSpecs["JP"] else {
            return XCTFail("JP address spec should exist")
        }
        XCTAssertTrue(jpSpec.fieldOrdering.contains(.city), "JP field ordering should include city")
        XCTAssertTrue(jpSpec.requiredFields.contains(.city), "JP required fields should include city")
    }

    func testConvertLinkBillingAddressToAddressDetails() {
        let linkBillingDetails = BillingAddress(
            name: "Test Testerson",
            line1: "123 Main St",
            line2: "Apt 4",
            city: "San Francisco",
            state: "CA",
            postalCode: "94102",
            countryCode: "US"
            )
        let addressDetails = AddressSectionElement.AddressDetails(billingAddress: linkBillingDetails, phone: "+1231231234")
        XCTAssertEqual(addressDetails.name, linkBillingDetails.name)
        XCTAssertEqual(addressDetails.phone, "+1231231234")
        XCTAssertEqual(addressDetails.address.city, linkBillingDetails.city)
        XCTAssertEqual(addressDetails.address.country, linkBillingDetails.countryCode)
        XCTAssertEqual(addressDetails.address.line1, linkBillingDetails.line1)
        XCTAssertEqual(addressDetails.address.line2, linkBillingDetails.line2)
        XCTAssertEqual(addressDetails.address.postalCode, linkBillingDetails.postalCode)
        XCTAssertEqual(addressDetails.address.state, linkBillingDetails.state)
    }
}
