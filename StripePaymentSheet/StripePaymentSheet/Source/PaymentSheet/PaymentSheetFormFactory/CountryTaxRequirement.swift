//
//  CountryTaxRequirement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/13/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore

/// Billing address fields needed to compute tax from the billing address.
enum CountryTaxRequirement {
    /// Collection mode per country; unlisted countries need country only.
    static let collectionModeByCountry: [String: AddressSectionElement.CollectionMode] = [
        "US": .autoCompletable,
        "PR": .autoCompletable,
        "CA": .countryAndPostal(countriesRequiringPostalCollection: ["CA"]),
        "GB": .countryAndPostal(countriesRequiringPostalCollection: ["GB"]),
        "IN": .countryAndPostal(countriesRequiringPostalCollection: ["IN"]),
    ]
}
