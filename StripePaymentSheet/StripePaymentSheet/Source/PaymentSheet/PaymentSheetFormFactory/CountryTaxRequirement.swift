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
    /// Fields to collect per country; unlisted countries only need the country.
    static let fieldsToCollectByCountry: [String: AddressSectionElement.FieldsToCollect] = [
        "US": .all,
        "PR": .all,
        "CA": .countryAndPostal,
        "GB": .countryAndPostal,
        "IN": .countryAndPostal,
    ]
}
