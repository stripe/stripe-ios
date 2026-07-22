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
            addressSpecProvider: specProvider,
            disableAutocomplete: true
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
            addressSpecProvider: specProvider,
            disableAutocomplete: true
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

    func testMinimumFieldsToCollectResolveInitialAndCountryChanges() throws {
        // Given country-specific minimums that can widen the default fields
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
            defaultFieldsToCollect: .country,
            minimumFieldsToCollectByCountry: [
                "US": .all,
                "CA": .countryAndPostal,
            ],
            disableAutocomplete: true
        )

        // Then the initial US minimum collects the full address
        XCTAssertDisplayed(sut.line1, in: sut)
        XCTAssertDisplayed(sut.postalCode, in: sut)

        // When the country is changed programmatically to CA
        sut.selectedCountryCode = "CA"

        // Then the CA minimum narrows collection from the US requirement to postal code
        XCTAssertNotDisplayed(sut.line1, in: sut)
        XCTAssertDisplayed(sut.postalCode, in: sut)

        // When the picker changes to an unlisted country
        sut.country.select(index: try XCTUnwrap(sut.countryCodes.firstIndex(of: "FR")))

        // Then the element falls back to its country-only default
        XCTAssertNotDisplayed(sut.line1, in: sut)
        XCTAssertNotDisplayed(sut.postalCode, in: sut)
    }

    func testCountryAndPostalCollectsPostalForAnyCountry() {
        // Given country-and-postal collection for a country outside the card minimum list
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "FR": AddressSpec(format: "ACZ", require: "ACZ", cityNameType: .city, stateNameType: .province, zip: "", zipNameType: .postal_code),
        ]
        let sut = AddressSectionElement(
            title: "",
            countries: ["FR"],
            locale: locale_enUS,
            addressSpecProvider: specProvider,
            defaults: .init(address: .init(country: "FR")),
            defaultFieldsToCollect: .countryAndPostal,
            disableAutocomplete: true
        )

        // Then the mode unconditionally collects the country's postal field
        XCTAssertNotDisplayed(sut.line1, in: sut)
        XCTAssertDisplayed(sut.postalCode, in: sut)
    }

    func testCountryMinimumDoesNotReduceDefaultFieldsToCollect() {
        // Given a country-only minimum on a full-address default
        let sut = AddressSectionElement(
            title: "",
            countries: ["US", "CA"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider,
            defaults: .init(address: .init(country: "US")),
            defaultFieldsToCollect: .all,
            minimumFieldsToCollectByCountry: ["US": .country],
            disableAutocomplete: true
        )

        // Then the country minimum does not narrow the full-address default
        XCTAssertDisplayed(sut.line1, in: sut)
        XCTAssertDisplayed(sut.postalCode, in: sut)

        // When changing to an unlisted country
        sut.selectedCountryCode = "CA"

        // Then the full-address default remains unchanged
        XCTAssertDisplayed(sut.line1, in: sut)
        XCTAssertDisplayed(sut.postalCode, in: sut)
    }

    func testUpdatingDefaultFieldsToCollectRebuildsCurrentCountry() {
        // Given an element collecting only country
        let sut = AddressSectionElement(
            title: "",
            countries: ["US"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider,
            defaultFieldsToCollect: .country,
            disableAutocomplete: true
        )
        XCTAssertNotDisplayed(sut.line1, in: sut)
        XCTAssertNotDisplayed(sut.postalCode, in: sut)

        // When the default changes to full address collection
        sut.defaultFieldsToCollect = .all

        // Then the current country is rebuilt with all fields
        XCTAssertDisplayed(sut.line1, in: sut)
        XCTAssertDisplayed(sut.postalCode, in: sut)

        // When the default changes to country and postal code
        sut.defaultFieldsToCollect = .countryAndPostal

        // Then the current country narrows to postal code
        XCTAssertNotDisplayed(sut.line1, in: sut)
        XCTAssertDisplayed(sut.postalCode, in: sut)
    }

    func testUpdatingDefaultFieldsToCollectPreservesCountryMinimum() {
        // Given full-address collection with a postal minimum for the selected country
        let sut = AddressSectionElement(
            title: "",
            countries: ["US"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider,
            defaultFieldsToCollect: .all,
            minimumFieldsToCollectByCountry: ["US": .countryAndPostal],
            disableAutocomplete: true
        )
        XCTAssertDisplayed(sut.line1, in: sut)
        XCTAssertDisplayed(sut.postalCode, in: sut)

        // When the default changes to country-only collection
        sut.defaultFieldsToCollect = .country

        // Then the selected country's postal minimum is preserved
        XCTAssertNotDisplayed(sut.line1, in: sut)
        XCTAssertDisplayed(sut.postalCode, in: sut)
    }

    func testCountryMinimumAllSupportsAutocomplete() {
        // Given autocomplete configured on a country minimum
        let sut = AddressSectionElement(
            title: "",
            countries: ["US", "CA"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider,
            defaults: .init(address: .init(country: "CA")),
            defaultFieldsToCollect: .country,
            minimumFieldsToCollectByCountry: [
                "US": .all,
            ],
            countriesSupportingAutocomplete: ["US"]
        )
        XCTAssertNil(sut.autoCompleteLine)

        // When changing to the overridden country
        sut.selectedCountryCode = "US"

        // Then the full address minimum starts in compact autocomplete
        XCTAssertNotNil(sut.autoCompleteLine)
        XCTAssertNotDisplayed(sut.line1, in: sut)
    }

    func testCountryMinimumsApplyToBillingSameAsShippingCountryChanges() {
        // Given a shipping address and country-specific field minimums
        let sut = AddressSectionElement(
            title: "",
            countries: ["US", "CA"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider,
            defaults: .init(address: .init(country: "US")),
            defaultFieldsToCollect: .country,
            minimumFieldsToCollectByCountry: [
                "US": .all,
                "CA": .countryAndPostal,
            ],
            disableAutocomplete: true,
            additionalFields: .init(billingSameAsShippingCheckbox: .enabled(isOptional: false))
        )

        // When re-selecting billing same as shipping from another country
        sut.selectedCountryCode = "CA"
        sut.sameAsCheckbox.didToggle(false)
        sut.sameAsCheckbox.didToggle(true)

        // Then the shipping country's full-address minimum is restored
        XCTAssertEqual(sut.selectedCountryCode, "US")
        XCTAssertDisplayed(sut.line1, in: sut)

        // When the selected shipping address changes to CA
        sut.sameAsCheckbox.isSelected = true
        sut.updateBillingSameAsShippingDefaultAddress(.init(country: "CA", postalCode: "A1A 1A1"))

        // Then the CA postal minimum and defaults are applied
        XCTAssertEqual(sut.selectedCountryCode, "CA")
        XCTAssertNotDisplayed(sut.line1, in: sut)
        XCTAssertDisplayed(sut.postalCode, in: sut)
        XCTAssertEqual(sut.postalCode?.text, "A1A 1A1")
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

    func testAutocompleteStartsCompactAndExpandsForManualEntry() {
        let sut = AddressSectionElement(
            title: "",
            countries: ["US"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider
        )

        XCTAssertEqual(sut.countriesSupportingAutocomplete, AddressSectionElement.defaultAutocompleteCountries)
        XCTAssertNotNil(sut.autoCompleteLine)
        XCTAssertNil(sut.line1)
        XCTAssertNil(sut.line2)
        XCTAssertNil(sut.city)
        XCTAssertNil(sut.state)
        XCTAssertNil(sut.postalCode)
        var updateCount = 0
        sut.didUpdate = { _ in updateCount += 1 }

        sut.beginManualEntry(with: "510 Townsend St.")

        XCTAssertEqual(updateCount, 1)
        XCTAssertNil(sut.autoCompleteLine)
        XCTAssertEqual(sut.line1?.text, "510 Townsend St.")
        guard let expandedLine1 = sut.line1 else {
            return XCTFail("Expected a visible line1 field")
        }
        XCTAssertTrue(sut.addressSection.elements.contains { $0 === expandedLine1 })
        XCTAssertLine1HasAutocompleteAccessory(sut)
    }

    func testAutocompleteStartsExpandedWhenAddressDefaultsArePresent() {
        let sut = AddressSectionElement(
            title: "",
            countries: ["US"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider,
            defaults: .init(address: .init(city: "San Francisco"))
        )

        XCTAssertNil(sut.autoCompleteLine)
        XCTAssertEqual(sut.city?.text, "San Francisco")
        XCTAssertLine1HasAutocompleteAccessory(sut)
    }

    func testAutocompleteStaysCompactWhenOnlyDefaultCountryIsPresent() {
        // A default country alone (no street address) shouldn't be treated as an
        // existing address to expand and show.
        let sut = AddressSectionElement(
            title: "",
            countries: ["US"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider,
            defaults: .init(address: .init(country: "US"))
        )

        XCTAssertNotNil(sut.autoCompleteLine)
        XCTAssertNil(sut.line1)
    }

    func testAutocompleteExpandsForUnsupportedCountryAndDoesNotCollapse() {
        let sut = AddressSectionElement(
            title: "",
            countries: ["US", "CA"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider,
            countriesSupportingAutocomplete: ["CA"]
        )

        XCTAssertEqual(sut.selectedCountryCode, "CA")
        XCTAssertNotNil(sut.autoCompleteLine)

        sut.selectedCountryCode = "US"

        XCTAssertNil(sut.autoCompleteLine)
        XCTAssertLine1DoesNotHaveAutocompleteAccessory(sut)

        sut.selectedCountryCode = "CA"

        XCTAssertNil(sut.autoCompleteLine)
        XCTAssertLine1HasAutocompleteAccessory(sut)
    }

    func testAutocompleteExpandsForEmptyManualEntry() {
        let sut = AddressSectionElement(
            title: "",
            countries: ["US"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider
        )

        sut.beginManualEntry(with: "")

        XCTAssertNil(sut.autoCompleteLine)
        XCTAssertLine1HasAutocompleteAccessory(sut)
    }

    func testSettingAddressExpandsAutocompleteAndPopulatesFields() {
        let sut = AddressSectionElement(
            title: "",
            countries: ["US"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider
        )
        let address = AddressSectionElement.AddressDetails.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "Floor 3",
            postalCode: "94103",
            state: "CA"
        )

        sut.setAddress(address)

        XCTAssertNil(sut.autoCompleteLine)
        XCTAssertEqual(sut.addressDetails.address, address)
        XCTAssertLine1HasAutocompleteAccessory(sut)
    }

    func testSettingEmptyAddressDoesNotExpandAutocomplete() {
        let sut = AddressSectionElement(
            title: "",
            countries: ["US"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider
        )

        sut.setAddress(.init())

        XCTAssertNotNil(sut.autoCompleteLine)
        XCTAssertNil(sut.line1)
    }

    func testAutocompleteDoesNotExpandForNonAddressDefaultsOrFieldUpdates() {
        let sut = AddressSectionElement(
            title: "",
            countries: ["US"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider,
            defaults: .init(name: "Jenny Rosen"),
            additionalFields: .init(name: .enabled())
        )

        XCTAssertNotNil(sut.autoCompleteLine)
        sut.name?.setText("Jane Doe")
        XCTAssertNotNil(sut.autoCompleteLine)
        XCTAssertNil(sut.line1)
    }

    func testAutocompleteCanBeDisabled() {
        let sut = AddressSectionElement(
            title: "",
            countries: ["US"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider,
            disableAutocomplete: true
        )

        XCTAssertNil(sut.autoCompleteLine)
        XCTAssertNotNil(sut.line1)
        XCTAssertLine1DoesNotHaveAutocompleteAccessory(sut)
    }

    func testChangingDefaultFieldsToCollectPreservesAutocompleteCountries() {
        let sut = AddressSectionElement(
            title: "",
            countries: ["US"],
            locale: locale_enUS,
            addressSpecProvider: dummyAddressSpecProvider,
            defaultFieldsToCollect: .country
        )

        sut.defaultFieldsToCollect = .all

        XCTAssertEqual(sut.countriesSupportingAutocomplete, AddressSectionElement.defaultAutocompleteCountries)
        XCTAssertNotNil(sut.autoCompleteLine)
        XCTAssertNil(sut.line1)
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
            addressSpecProvider: specProvider,
            disableAutocomplete: true
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
            addressSpecProvider: specProvider,
            disableAutocomplete: true
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

    private func XCTAssertLine1HasAutocompleteAccessory(
        _ sut: AddressSectionElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let configuration = sut.line1?.configuration as? TextFieldElement.Address.LineConfiguration else {
            return XCTFail("Expected line1 to use LineConfiguration", file: file, line: line)
        }
        guard case .line1Autocompletable = configuration.lineType else {
            return XCTFail("Expected line1 to show autocomplete", file: file, line: line)
        }
    }

    private func XCTAssertLine1DoesNotHaveAutocompleteAccessory(
        _ sut: AddressSectionElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let configuration = sut.line1?.configuration as? TextFieldElement.Address.LineConfiguration else {
            return XCTFail("Expected line1 to use LineConfiguration", file: file, line: line)
        }
        guard case .line1 = configuration.lineType else {
            return XCTFail("Expected line1 to omit autocomplete", file: file, line: line)
        }
    }

    private func XCTAssertDisplayed(
        _ element: Element?,
        in sut: AddressSectionElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let element else {
            return XCTFail("Expected field to exist", file: file, line: line)
        }
        XCTAssertTrue(sut.addressSection.elements.contains { $0 === element }, file: file, line: line)
    }

    private func XCTAssertNotDisplayed(
        _ element: Element?,
        in sut: AddressSectionElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let element else { return }
        XCTAssertFalse(sut.addressSection.elements.contains { $0 === element }, file: file, line: line)
    }
}
