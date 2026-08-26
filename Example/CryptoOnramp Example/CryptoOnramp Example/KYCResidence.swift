//
//  KYCResidence.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/25/26.
//

import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// Represents the residence modes selectable in `KYCInfoView`.
///
/// `KYCInfoView` uses the selected residence to configure national ID collection, prefill the editable address country,
/// determine the local source currency, and preserve the existing EU-specific flow. Raw values match the values returned
/// by `v1/customer_info` in `kyc_region`.
enum KYCResidence: String, CaseIterable, Hashable, Identifiable {

    /// Describes a national ID field associated with a KYC residence in the example app.
    struct NationalIDConfiguration {

        /// The API value submitted with the ID number.
        let type: IdType

        /// The title displayed above the ID number field.
        let title: LocalizedStringKey

        /// The placeholder displayed in the ID number field.
        let placeholder: LocalizedStringKey
    }

    /// United States KYC behavior, including Social Security Number collection.
    case unitedStates = "US"

    /// European Union KYC behavior, including EU-specific personal information and subsequent compliance collection.
    case europeanUnion = "EU"

    /// Canada KYC behavior, including Social Insurance Number collection.
    case canada = "CA"

    /// Colombia KYC behavior, including Número de Identificación Tributaria collection.
    case colombia = "CO"

    /// Philippines KYC behavior, including Taxpayer Identification Number collection.
    case philippines = "PH"

    /// The name displayed in the residence picker.
    var displayName: String {
        switch self {
        case .unitedStates:
            return "United States"
        case .europeanUnion:
            return "European Union"
        case .canada:
            return "Canada"
        case .colombia:
            return "Colombia"
        case .philippines:
            return "Philippines"
        }
    }

    /// The address country code used to prefill the KYC form, or `nil` when the user must supply a specific country.
    var countryCode: String? {
        switch self {
        case .unitedStates:
            return "US"
        case .europeanUnion:
            return nil
        case .canada:
            return "CA"
        case .colombia:
            return "CO"
        case .philippines:
            return "PH"
        }
    }

    /// The national ID field configuration for this residence, or `nil` when KYC does not collect a national ID number.
    var nationalIDConfiguration: NationalIDConfiguration? {
        switch self {
        case .unitedStates:
            return NationalIDConfiguration(
                type: .socialSecurityNumber,
                title: "Social Security Number",
                placeholder: "Enter your SSN"
            )
        case .europeanUnion:
            return nil
        case .canada:
            return NationalIDConfiguration(
                type: .canadianSocialInsuranceNumber,
                title: "Social Insurance Number (SIN)",
                placeholder: "Enter your SIN"
            )
        case .colombia:
            return NationalIDConfiguration(
                type: .colombianTaxIdentificationNumber,
                title: "Número de Identificación Tributaria (NIT)",
                placeholder: "Enter your NIT"
            )
        case .philippines:
            return NationalIDConfiguration(
                type: .philippinesTaxpayerIdentificationNumber,
                title: "Taxpayer Identification Number (TIN)",
                placeholder: "Enter your TIN"
            )
        }
    }

    /// Whether the example app supports level 0 KYC collection and subsequent step-up for this residence.
    var supportsLevel0KYC: Bool {
        switch self {
        case .unitedStates:
            return true
        case .europeanUnion, .canada, .colombia, .philippines:
            return false
        }
    }

    /// Whether the address state or equivalent administrative area is required for this residence.
    var requiresState: Bool {
        self == .unitedStates
    }

    /// Whether this residence follows the existing EU compliance and downstream flow.
    var followsEUFlow: Bool {
        self == .europeanUnion
    }

    /// The default local source currency code for this residence.
    var localCurrencyCode: String {
        switch self {
        case .unitedStates:
            return "usd"
        case .europeanUnion:
            return "eur"
        case .canada:
            return "cad"
        case .colombia:
            return "cop"
        case .philippines:
            return "php"
        }
    }

    // MARK: - Identifiable

    var id: Self {
        self
    }
}
