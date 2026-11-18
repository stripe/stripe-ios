//
//  InlineAddressFormState.swift
//  StripePaymentSheet
//

import Combine
import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/// Holds the input of an `InlineAddressFormView`. Keep one instance for the life of the screen that
/// shows the form, so input survives SwiftUI view updates.
@_spi(InternalOnlyAPI)
@MainActor
public final class InlineAddressFormState: ObservableObject {
    /// An address as entered so far. Any field can be empty or invalid.
    public struct EnteredAddress: Equatable {
        /// The address fields.
        public let address: PaymentSheet.Address
        /// The customer's full name.
        public let name: String?
        /// The customer's phone number in E.164 format, if the form collects a valid one.
        public let phone: String?
    }

    /// The address entered so far, including incomplete and invalid fields. `nil` until address
    /// formats load.
    @Published public private(set) var enteredAddress: EnteredAddress?

    /// The entered address once every required field is valid, or `nil` otherwise.
    @Published public private(set) var completeAddress: AddressViewController.AddressDetails?

    /// Whether a field in the form is being edited.
    @Published public private(set) var isEditing = false

    /// Whether the entered values differ from the initial ones.
    public var hasChanges: Bool {
        guard let addressSection else { return false }
        if addressSection.addressDetails != initialFormSnapshot { return true }
        if addressSection.phone?.selectedCountryCode != initialPhoneCountryCode { return true }
        return false
    }

    /// The form's fields, once address formats load.
    @Published private(set) var addressSection: AddressSectionElement?

    private let defaultValues: AddressViewController.Configuration.DefaultAddressDetails
    private let allowedCountries: [String]
    private let nameField: AddressViewController.Configuration.NameField
    private let phone: AddressViewController.Configuration.AdditionalFields.FieldConfiguration
    private let appearance: PaymentSheet.Appearance
    private let addressSpecProvider: AddressSpecProvider

    private var initialFormSnapshot: AddressSectionElement.AddressDetails?
    private var initialPhoneCountryCode: String?

    /// Creates the state for an address form without autocomplete.
    /// - Parameters:
    ///   - defaultValues: The values to prefill the fields with.
    ///   - allowedCountries: The countries the customer can select, or every country if empty. A
    ///     `defaultValues` address in another country doesn't prefill the fields.
    ///   - nameField: Whether the form collects a name. A hidden name is `defaultValues.name`.
    ///   - phone: Whether the form collects a phone number, and whether it is required.
    ///   - appearance: The appearance of the fields. The fields take it when address formats load.
    public convenience init(
        defaultValues: AddressViewController.Configuration.DefaultAddressDetails,
        allowedCountries: [String],
        nameField: AddressViewController.Configuration.NameField,
        phone: AddressViewController.Configuration.AdditionalFields.FieldConfiguration,
        appearance: PaymentSheet.Appearance
    ) {
        self.init(
            defaultValues: defaultValues,
            allowedCountries: allowedCountries,
            nameField: nameField,
            phone: phone,
            appearance: appearance,
            addressSpecProvider: .shared
        )
    }

    init(
        defaultValues: AddressViewController.Configuration.DefaultAddressDetails,
        allowedCountries: [String],
        nameField: AddressViewController.Configuration.NameField,
        phone: AddressViewController.Configuration.AdditionalFields.FieldConfiguration,
        appearance: PaymentSheet.Appearance,
        addressSpecProvider: AddressSpecProvider
    ) {
        self.defaultValues = defaultValues
        self.allowedCountries = allowedCountries
        self.nameField = nameField
        self.phone = phone
        self.appearance = appearance
        self.addressSpecProvider = addressSpecProvider

        if addressSpecProvider.countries.isEmpty {
            addressSpecProvider.loadAddressSpecs { [weak self] in
                DispatchQueue.main.async {
                    self?.makeAddressSection()
                }
            }
        } else {
            makeAddressSection()
        }
    }

    /// Shows an error on every field that is incomplete or invalid.
    public func validate() {
        addressSection?.showAllValidationErrors()
    }

    private func makeAddressSection() {
        let additionalFields = AddressViewController.Configuration.AdditionalFields(phone: phone)
        // An address from a country the form doesn't offer would fill another country's fields.
        let isCountryAllowed = defaultValues.isCountryAllowed(allowedCountries)
        let prefilledValues = isCountryAllowed ? defaultValues : .init()
        let addressSection = AddressSectionElement(
            countries: allowedCountries.isEmpty ? nil : allowedCountries,
            addressSpecProvider: addressSpecProvider,
            defaults: .init(from: prefilledValues),
            defaultFieldsToCollect: .all,
            disableAutocomplete: true,
            additionalFields: .init(from: additionalFields, nameField: nameField),
            theme: appearance.asElementsTheme
        )
        addressSection.delegate = self
        initialFormSnapshot = addressSection.addressDetails
        initialPhoneCountryCode = addressSection.phone?.selectedCountryCode
        self.addressSection = addressSection
        updateAddresses()
    }

    private func updateAddresses() {
        guard let addressSection else { return }
        let details = addressSection.addressDetails
        let name: String?
        switch nameField {
        case .auto:
            name = details.name?.nonEmpty
        case .never:
            // The customer can't edit a hidden name, so the form keeps the default one.
            name = defaultValues.name
        }
        enteredAddress = EnteredAddress(
            address: PaymentSheet.Address(
                city: details.address.city?.nonEmpty,
                country: details.address.country?.nonEmpty,
                line1: details.address.line1?.nonEmpty,
                line2: details.address.line2?.nonEmpty,
                postalCode: details.address.postalCode?.nonEmpty,
                state: details.address.state?.nonEmpty
            ),
            name: name,
            phone: details.phone?.nonEmpty
        )
        completeAddress = addressSection.completeAddressDetails(
            nameField: nameField,
            defaultName: defaultValues.name,
            isCheckboxSelected: nil
        )
    }

    private func updateIsEditing() {
        let isEditing = addressSection?.view.firstResponder() != nil
        if self.isEditing != isEditing {
            self.isEditing = isEditing
        }
    }
}

// MARK: - ElementDelegate
// Elements call their delegate on the main thread.
@_spi(InternalOnlyAPI) extension InlineAddressFormState: @preconcurrency ElementDelegate {
    @_spi(InternalOnlyAPI) public func didUpdate(element: Element) {
        updateAddresses()
        // Moving between fields ends one field's editing before the next one begins, so check
        // after both have happened.
        DispatchQueue.main.async { [weak self] in
            self?.updateIsEditing()
        }
    }

    @_spi(InternalOnlyAPI) public func continueToNextField(element: Element) {
        // no-op
    }
}
