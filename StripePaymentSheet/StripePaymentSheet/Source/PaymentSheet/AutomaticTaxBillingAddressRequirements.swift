//
//  AutomaticTaxBillingAddressRequirements.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/24/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

/// The billing address fields needed to compute automatic tax.
enum AutomaticTaxBillingAddressRequirements {
    private enum Field: Hashable {
        case line1
        case city
        case state
        case postalCode
    }

    private enum Requirement {
        case country
        case countryAndPostal
        case fullAddress(requiredFields: Set<Field>)

        var fieldsToCollect: AddressSectionElement.FieldsToCollect {
            switch self {
            case .country:
                return .country
            case .countryAndPostal:
                return .countryAndPostal
            case .fullAddress:
                return .all
            }
        }

        var requiredFields: Set<Field> {
            switch self {
            case .country:
                return []
            case .countryAndPostal:
                return [.postalCode]
            case .fullAddress(let requiredFields):
                return requiredFields
            }
        }
    }

    private static let requirementsByCountry: [String: Requirement] = [
        "US": .fullAddress(requiredFields: [.line1, .city, .state, .postalCode]),
        "PR": .fullAddress(requiredFields: [.line1, .city, .postalCode]),
        "CA": .countryAndPostal,
        "GB": .countryAndPostal,
        "IN": .countryAndPostal,
    ]

    /// Per-country collection overrides used when building payment method forms.
    static let minimumFieldsToCollectByCountry = requirementsByCountry.mapValues(\.fieldsToCollect)

    /// Whether a saved payment method address contains the fields required to calculate tax.
    static func areSatisfied(by address: STPPaymentMethodAddress?) -> Bool {
        guard let address,
              let country = address.country?.nonEmpty?.uppercased() else {
            return false
        }

        let requirement = requirementsByCountry[country] ?? .country
        return requirement.requiredFields.allSatisfy { field in
            switch field {
            case .line1:
                return address.line1?.nonEmpty != nil
            case .city:
                return address.city?.nonEmpty != nil
            case .state:
                return address.state?.nonEmpty != nil
            case .postalCode:
                return address.postalCode?.nonEmpty != nil
            }
        }
    }
}
