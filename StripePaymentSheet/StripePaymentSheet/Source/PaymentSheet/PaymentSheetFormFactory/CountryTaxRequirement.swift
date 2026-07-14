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
    private static let requiredModesByCountry: [String: AddressSectionElement.CollectionMode] = [
        "US": .autoCompletable,
        "CA": .countryPostalAndState,
    ]

    /// Per-country collection mode overrides for `AddressSectionElement`, widening `baseCollectionMode`
    /// to satisfy each country's tax requirement.
    static func collectionModeOverrides(
        for baseCollectionMode: AddressSectionElement.CollectionMode
    ) -> [String: AddressSectionElement.CollectionMode] {
        requiredModesByCountry.compactMapValues { requiredMode in
            let widened = baseCollectionMode.widened(toCollectAtLeast: requiredMode)
            return widened == baseCollectionMode ? nil : widened
        }
    }
}

extension AddressSectionElement.CollectionMode {
    /// Returns this mode widened to collect at least what `requiredMode` collects.
    fileprivate func widened(toCollectAtLeast requiredMode: AddressSectionElement.CollectionMode) -> AddressSectionElement.CollectionMode {
        var mode = self
        if requiredMode.collectsFullAddress && !mode.collectsFullAddress {
            mode = .autoCompletable
        }
        if requiredMode.collectsStateOrProvince && !mode.collectsStateOrProvince {
            mode = .countryPostalAndState
        }
        return mode
    }

    /// Whether this mode collects the full street address. `.noCountry` counts: it collects every
    /// address field and gathers the country separately, so it never needs widening.
    private var collectsFullAddress: Bool {
        switch self {
        case .all, .autoCompletable, .allWithAutocomplete, .noCountry:
            return true
        case .countryAndPostal, .countryPostalAndState:
            return false
        @unknown default:
            return false
        }
    }

    /// Whether this mode collects the state or province.
    private var collectsStateOrProvince: Bool {
        switch self {
        case .countryPostalAndState, .all, .autoCompletable, .allWithAutocomplete, .noCountry:
            return true
        case .countryAndPostal:
            return false
        @unknown default:
            return false
        }
    }
}
