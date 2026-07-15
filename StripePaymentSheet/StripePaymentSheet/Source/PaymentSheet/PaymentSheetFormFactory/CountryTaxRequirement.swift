//
//  CountryTaxRequirement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/13/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore

/// Per-country billing-address fields needed to compute tax for Checkout Sessions whose tax
/// is sourced from the billing address.
enum CountryTaxRequirement {
    /// The minimum billing-address fields each country needs before tax can be calculated,
    /// expressed as the collection mode to widen to when the base mode collects less.
    /// Countries not in the map only need the country itself.
    static let minimumFieldsByCountry: [String: AddressSectionElement.CollectionMode] = [
        "US": .autoCompletable,
        "PR": .autoCompletable,
        "CA": .countryAndPostal(countriesRequiringPostalCollection: ["CA"]),
        "GB": .countryAndPostal(countriesRequiringPostalCollection: ["GB"]),
        "IN": .countryAndPostal(countriesRequiringPostalCollection: ["IN"]),
    ]
}
