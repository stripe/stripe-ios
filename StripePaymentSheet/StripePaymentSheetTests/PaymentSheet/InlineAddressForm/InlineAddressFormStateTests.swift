//
//  InlineAddressFormStateTests.swift
//  StripePaymentSheetTests
//

@_spi(InternalOnlyAPI) @testable import StripeCore
@_spi(InternalOnlyAPI) @testable import StripePaymentSheet
@_spi(InternalOnlyAPI) @testable import StripeUICore
import XCTest

@MainActor
final class InlineAddressFormStateTests: XCTestCase {
    func testPrefilledValidAddressIsComplete() {
        // Given a form prefilled with a valid address and name
        let state = makeState(defaultValues: .init(address: Self.validAddress, name: "Jane Doe"))

        // Then the complete address matches the prefilled values
        let completeAddress = state.completeAddress
        XCTAssertEqual(completeAddress?.name, "Jane Doe")
        XCTAssertEqual(completeAddress?.address.line1, "354 Oyster Point Blvd")
        XCTAssertEqual(completeAddress?.address.city, "South San Francisco")
        XCTAssertEqual(completeAddress?.address.postalCode, "94080")
        XCTAssertEqual(completeAddress?.address.state, "CA")
        XCTAssertEqual(completeAddress?.address.country, "US")
    }

    func testIncompleteAddressIsEnteredButNotComplete() {
        // Given a form prefilled with an address that's missing its city
        var address = Self.validAddress
        address.city = nil
        let state = makeState(defaultValues: .init(address: address, name: "Jane Doe"))

        // Then the entered address has the prefilled values, but there is no complete address
        XCTAssertNil(state.completeAddress)
        XCTAssertEqual(state.enteredAddress?.address.line1, "354 Oyster Point Blvd")
        XCTAssertNil(state.enteredAddress?.address.city)
        XCTAssertEqual(state.enteredAddress?.name, "Jane Doe")
    }

    func testAddressOutsideAllowedCountriesIsNotPrefilled() {
        // Given a form for US addresses prefilled with a Canadian address
        let address = PaymentSheet.Address(
            city: "Toronto",
            country: "CA",
            line1: "123 Main St",
            postalCode: "M5V 2T6",
            state: "ON"
        )
        let state = makeState(defaultValues: .init(address: address, name: "Jane Doe"))

        // Then the fields stay empty
        XCTAssertEqual(state.enteredAddress?.address.country, "US")
        XCTAssertNil(state.enteredAddress?.address.line1)
        XCTAssertNil(state.enteredAddress?.address.city)
        XCTAssertNil(state.enteredAddress?.name)
        XCTAssertFalse(state.hasChanges)
    }

    func testEditingCompletesAddress() {
        // Given a form prefilled with a valid address but no name
        let state = makeState(defaultValues: .init(address: Self.validAddress))
        XCTAssertNil(state.completeAddress)
        XCTAssertFalse(state.hasChanges)

        // When the customer enters a name
        state.addressSection?.name?.setText("Jane Doe")

        // Then the address is complete and counts as changed
        XCTAssertEqual(state.enteredAddress?.name, "Jane Doe")
        XCTAssertEqual(state.completeAddress?.name, "Jane Doe")
        XCTAssertTrue(state.hasChanges)
    }

    func testHiddenNameFieldKeepsDefaultName() {
        // Given a form that hides the name field and has a default name
        let state = makeState(
            defaultValues: .init(address: Self.validAddress, name: "Jane Doe"),
            nameField: .never
        )

        // Then the form has no name field, and both addresses keep the default name
        XCTAssertNil(state.addressSection?.name)
        XCTAssertEqual(state.enteredAddress?.name, "Jane Doe")
        XCTAssertEqual(state.completeAddress?.name, "Jane Doe")
    }

    func testValidateShowsErrorsOnEmptyFields() {
        // Given an empty form
        let state = makeState(defaultValues: .init())
        guard let line1 = state.addressSection?.line1 else {
            return XCTFail("Expected an address line 1 field")
        }
        XCTAssertFalse(line1.validationState.isDisplayingError)

        // When the form is validated
        state.validate()

        // Then the empty required field shows its error
        XCTAssertTrue(line1.validationState.isDisplayingError)
    }

    func testFormHasNoAutocomplete() {
        // Given an empty form for a country that supports autocomplete elsewhere
        let state = makeState(defaultValues: .init(address: .init(country: "US")))

        // Then the form shows address fields instead of the autocomplete trigger
        XCTAssertNil(state.addressSection?.autoCompleteLine)
        XCTAssertNotNil(state.addressSection?.line1)
    }

    private func makeState(
        defaultValues: AddressViewController.Configuration.DefaultAddressDetails,
        nameField: AddressViewController.Configuration.NameField = .auto
    ) -> InlineAddressFormState {
        InlineAddressFormState(
            defaultValues: defaultValues,
            allowedCountries: ["US"],
            nameField: nameField,
            phone: .hidden,
            appearance: .default,
            addressSpecProvider: makeAddressSpecProvider()
        )
    }

    private func makeAddressSpecProvider() -> AddressSpecProvider {
        let addressSpecProvider = AddressSpecProvider()
        addressSpecProvider.addressSpecs = [
            "US": AddressSpec(
                format: "NOACSZ",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "",
                zipNameType: .zip
            ),
        ]
        return addressSpecProvider
    }

    private static let validAddress = PaymentSheet.Address(
        city: "South San Francisco",
        country: "US",
        line1: "354 Oyster Point Blvd",
        postalCode: "94080",
        state: "CA"
    )
}

private extension ElementValidationState {
    var isDisplayingError: Bool {
        if case .invalid(_, let shouldDisplay) = self {
            return shouldDisplay
        }
        return false
    }
}
