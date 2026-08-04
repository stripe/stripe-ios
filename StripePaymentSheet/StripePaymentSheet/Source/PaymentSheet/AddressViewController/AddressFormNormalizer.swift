//
//  AddressFormNormalizer.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/4/26.

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

enum AddressFormNormalizer {
    enum AddressSource {
        case defaultAddress
        case fallbackAddress
    }

    static func normalize(
        defaultAddress: PaymentSheet.Address,
        fallbackAddress: PaymentSheet.Address?,
        allowedCountries: [String],
        addressSpecProvider: AddressSpecProvider
    ) -> PaymentSheet.Address? {
        let address: PaymentSheet.Address
        switch addressSource(
            defaultAddress: defaultAddress,
            fallbackAddress: fallbackAddress,
            allowedCountries: allowedCountries
        ) {
        case .defaultAddress:
            address = defaultAddress
        case .fallbackAddress:
            guard let fallbackAddress else { return nil }
            address = fallbackAddress
        case nil:
            return nil
        }

        let addressSection = AddressSectionElement(
            countries: allowedCountries.isEmpty ? nil : allowedCountries,
            addressSpecProvider: addressSpecProvider,
            defaults: .init(address: address.addressSectionAddress),
            defaultFieldsToCollect: .all,
            disableAutocomplete: true
        )
        return normalizedAddress(from: addressSection)
    }

    static func addressSource(
        defaultAddress: PaymentSheet.Address,
        fallbackAddress: PaymentSheet.Address?,
        allowedCountries: [String]
    ) -> AddressSource? {
        if isCompatible(defaultAddress, allowedCountries: allowedCountries) {
            return .defaultAddress
        }
        if let fallbackAddress,
           isCompatible(fallbackAddress, allowedCountries: allowedCountries) {
            return .fallbackAddress
        }
        return nil
    }

    static func isCompatible(
        _ address: PaymentSheet.Address,
        allowedCountries: [String]
    ) -> Bool {
        guard !address.isEmpty else { return false }
        guard !allowedCountries.isEmpty else { return true }
        guard let country = address.country else { return true }
        return allowedCountries.contains(country)
    }

    static func normalizedAddress(from addressSection: AddressSectionElement) -> PaymentSheet.Address? {
        guard case .valid = addressSection.validationState,
              let line1 = addressSection.line1?.text.nonEmpty else {
            return nil
        }

        return PaymentSheet.Address(
            city: addressSection.city?.text.nonEmpty,
            country: addressSection.selectedCountryCode,
            line1: line1,
            line2: addressSection.line2?.text.nonEmpty,
            postalCode: addressSection.postalCode?.text.nonEmpty,
            state: addressSection.state?.rawData.nonEmpty
        )
    }
}
