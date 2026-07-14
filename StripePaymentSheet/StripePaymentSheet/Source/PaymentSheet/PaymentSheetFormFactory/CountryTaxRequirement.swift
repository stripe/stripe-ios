//
//  CountryTaxRequirement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/13/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore

/// The billing-address fields a country needs collected in order to compute tax.
///
/// Only relevant to Checkout Sessions whose tax is sourced from the billing address. Callers widen the
/// base form to satisfy the requirement for the selected country. Recomputing from the base as the country
/// changes lets fields narrow again, but never below the base. See
/// `AddressSectionElement.CollectionMode.widened(toSatisfy:)`.
enum CountryTaxRequirement: Equatable {
    /// Nothing beyond the base form is required (most countries).
    case none
    /// The full street address, collected via autocomplete (e.g. the US).
    case fullAddress
    /// The state or province (e.g. Canada).
    case stateOrProvince

    /// The tax requirement for the given billing country.
    init(country: String) {
        switch country.uppercased() {
        case "US":
            self = .fullAddress
        case "CA":
            self = .stateOrProvince
        default:
            self = .none
        }
    }
}

extension AddressSectionElement.CollectionMode {
    /// Returns this mode widened to satisfy `requirement`. If this mode already collects what the
    /// requirement needs, it is returned unchanged — we only ever add fields, never remove them.
    func widened(toSatisfy requirement: CountryTaxRequirement) -> AddressSectionElement.CollectionMode {
        switch requirement {
        case .none:
            return self
        case .fullAddress:
            return collectsFullAddress ? self : .autoCompletable
        case .stateOrProvince:
            return collectsStateOrProvince ? self : .countryPostalAndState
        }
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
