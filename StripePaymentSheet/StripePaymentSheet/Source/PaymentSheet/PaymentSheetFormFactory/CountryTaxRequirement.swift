//
//  CountryTaxRequirement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/13/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore

/// Per-country billing-address collection modes needed to compute tax for Checkout Sessions whose tax
/// is sourced from the billing address. Countries whose requirement the base mode already satisfies
/// are omitted so the form falls back to the base mode as the user changes country.
enum CountryTaxRequirement {
    /// The minimum billing-address fields a country needs before tax can be calculated.
    private enum Requirement {
        /// All fields defined by the country's address spec (e.g. `US`, `PR`).
        case fullAddress
        /// The postal code only (e.g. `CA`, `GB`, `IN`).
        case postalCode
    }

    private static let requirementsByCountry: [String: Requirement] = [
        "US": .fullAddress,
        "PR": .fullAddress,
        "CA": .postalCode,
        "GB": .postalCode,
        "IN": .postalCode,
    ]

    /// Per-country collection mode overrides for `AddressSectionElement`, widening `baseCollectionMode`
    /// to satisfy each country's tax requirement. Countries the base mode already satisfies are omitted.
    static func collectionModeOverrides(
        for baseCollectionMode: AddressSectionElement.CollectionMode
    ) -> [String: AddressSectionElement.CollectionMode] {
        var overrides: [String: AddressSectionElement.CollectionMode] = [:]
        for (country, requirement) in requirementsByCountry {
            switch requirement {
            case .fullAddress:
                if !baseCollectionMode.collectsFullAddress {
                    overrides[country] = .autoCompletable
                }
            case .postalCode:
                if !baseCollectionMode.collectsFullAddress && !baseCollectionMode.collectsPostal(for: country) {
                    overrides[country] = .countryAndPostal(countriesRequiringPostalCollection: [country])
                }
            }
        }
        return overrides
    }
}

extension AddressSectionElement.CollectionMode {
    /// Whether this mode collects the full street address. `.noCountry` counts: it collects every
    /// address field and gathers the country separately, so it never needs widening.
    fileprivate var collectsFullAddress: Bool {
        switch self {
        case .all, .autoCompletable, .allWithAutocomplete, .noCountry:
            return true
        case .countryAndPostal:
            return false
        @unknown default:
            return false
        }
    }

    /// Whether this mode collects the postal code for `country`.
    fileprivate func collectsPostal(for country: String) -> Bool {
        switch self {
        case .all, .autoCompletable, .allWithAutocomplete, .noCountry:
            return true
        case .countryAndPostal(let countriesRequiringPostalCollection):
            return countriesRequiringPostalCollection.contains(country)
        @unknown default:
            return false
        }
    }
}
