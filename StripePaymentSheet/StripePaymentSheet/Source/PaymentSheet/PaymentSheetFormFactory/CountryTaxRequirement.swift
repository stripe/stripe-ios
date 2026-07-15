//
//  CountryTaxRequirement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/13/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore

/// Billing-address fields each country needs to compute tax from the billing address.
enum CountryTaxRequirement {
    /// Minimum fields per country; countries not listed need only the country itself.
    static let minimumFieldsByCountry: [String: AddressSectionElement.CollectionMode] = [
        "US": .autoCompletable,
        "PR": .autoCompletable,
        "CA": .countryAndPostal(countriesRequiringPostalCollection: ["CA"]),
        "GB": .countryAndPostal(countriesRequiringPostalCollection: ["GB"]),
        "IN": .countryAndPostal(countriesRequiringPostalCollection: ["IN"]),
    ]
}
