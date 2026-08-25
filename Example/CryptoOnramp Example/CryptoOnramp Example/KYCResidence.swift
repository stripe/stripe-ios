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
/// determine whether initial collection must include level 1 fields, and preserve the existing EU-specific flow.
enum KYCResidence: CaseIterable, Hashable, Identifiable {

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
    case unitedStates

    /// European Union KYC behavior, including EU-specific personal information and subsequent compliance collection.
    case europeanUnion

    /// Canada KYC behavior, including Social Insurance Number collection.
    case canada

    /// Colombia KYC behavior, including Número de Identificación Tributaria collection.
    case colombia

    /// Philippines KYC behavior, including Taxpayer Identification Number collection.
    case philippines

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

    /// Whether initial KYC collection must include the date of birth and national ID number for this residence.
    var requiresLevel1DuringInitialCollection: Bool {
        // TODO: Confirm whether these identifiers should remain required during L0 KYC collection.
        switch self {
        case .canada, .colombia, .philippines:
            return true
        case .unitedStates, .europeanUnion:
            return false
        }
    }

    /// Whether the address state or equivalent administrative area is required for this residence.
    var requiresState: Bool {
        // TODO: Confirm whether an address state, province, or department is required for CA, CO, or PH.
        self == .unitedStates
    }

    /// Whether this residence follows the existing EU compliance and downstream flow.
    var followsEUFlow: Bool {
        // TODO: Revisit this classification if CA, CO, or PH receive dedicated kycRegion or source_currency behavior.
        self == .europeanUnion
    }

    // MARK: - Identifiable

    var id: Self {
        self
    }
}
