//
//  STPAddress+BasicUI.swift
//  StripeiOS
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

/// What set of billing address information you need to collect from your user.
///
/// @note If the user is from a country that does not use zip/postal codes,
/// the user may not be asked for one regardless of this setting.
@objc
public enum STPBillingAddressFields: UInt {
    /// No billing address information
    case none
    /// Just request the user's billing postal code
    case postalCode
    /// Request the user's full billing address
    case full
    /// Just request the user's billing name
    case name
    /// Just request the user's billing ZIP (synonym for STPBillingAddressFieldsZip)
    @available(*, deprecated, message: "Use STPBillingAddressFields.postalCode instead")
    case zip
}

extension STPAddress {

    /// Checks if this STPAddress has the level of valid address information
    /// required by the passed in setting.
    /// - Parameter requiredFields: The required level of billing address information to
    /// check against.
    /// - Returns: YES if this address contains at least the necessary information,
    /// NO otherwise.
    @objc
    public func containsRequiredFields(_ requiredFields: STPBillingAddressFields) -> Bool {
        switch requiredFields {
        case .none:
            return true
        case .postalCode:
            return STPPostalCodeValidator.validationState(
                forPostalCode: postalCode,
                countryCode: country
            ) == .valid
        case .full:
            return hasValidPostalAddress()
        case .name:
            return (name?.count ?? 0) > 0
        default:
            fatalError()
        }
    }

    /// Checks if this STPAddress has any content (possibly invalid) in any of the
    /// desired billing address fields.
    /// Where `containsRequiredFields:` validates that this STPAddress contains valid data in
    /// all of the required fields, this method checks for the existence of *any* data.
    /// For example, if `desiredFields` is `STPBillingAddressFieldsZip`, this will check
    /// if the postalCode is empty.
    /// Note: When `desiredFields == STPBillingAddressFieldsNone`, this method always returns
    /// NO.
    /// @parameter desiredFields The billing address information the caller is interested in.
    /// - Returns: YES if there is any data in this STPAddress that's relevant for those fields.
    @objc(containsContentForBillingAddressFields:)
    public func containsContent(for desiredFields: STPBillingAddressFields) -> Bool {
        switch desiredFields {
        case .none:
            return false
        case .postalCode:
            return (postalCode?.count ?? 0) > 0
        case .full:
            return hasPartialPostalAddress()
        case .name:
            return (name?.count ?? 0) > 0
        default:
            fatalError()
        }
    }

    /// Checks if this STPAddress has the level of valid address information
    /// required by the passed in setting.
    /// Note: When `requiredFields == nil`, this method always returns
    /// YES.
    /// - Parameter requiredFields: The required shipping address information to check against.
    /// - Returns: YES if this address contains at least the necessary information,
    /// NO otherwise.
    @objc
    public func containsRequiredShippingAddressFields(
        _ requiredFields: Set<STPContactField>?
    )
        -> Bool
    {
        guard let requiredFields = requiredFields else {
            return true
        }
        var containsFields = true

        if requiredFields.contains(.name) {
            containsFields = containsFields && (name?.count ?? 0) > 0
        }
        if requiredFields.contains(.emailAddress) {
            containsFields =
                containsFields && STPEmailAddressValidator.stringIsValidEmailAddress(email)
        }
        if requiredFields.contains(.phoneNumber) {
            containsFields =
                containsFields
                && STPPhoneNumberValidator.stringIsValidPhoneNumber(
                    phone ?? "",
                    forCountryCode: country
                )
        }
        if requiredFields.contains(.postalAddress) {
            containsFields = containsFields && hasValidPostalAddress()
        }
        return containsFields
    }

    /// Checks if this STPAddress has any content (possibly invalid) in any of the
    /// desired shipping address fields.
    /// Where `containsRequiredShippingAddressFields:` validates that this STPAddress
    /// contains valid data in all of the required fields, this method checks for the
    /// existence of *any* data.
    /// Note: When `desiredFields == nil`, this method always returns
    /// NO.
    /// @parameter desiredFields The shipping address information the caller is interested in.
    /// - Returns: YES if there is any data in this STPAddress that's relevant for those fields.
    @objc
    public func containsContent(
        forShippingAddressFields desiredFields: Set<STPContactField>?
    )
        -> Bool
    {
        guard let desiredFields = desiredFields else {
            return false
        }
        return (desiredFields.contains(.name) && (name?.count ?? 0) > 0)
            || (desiredFields.contains(.emailAddress) && (email?.count ?? 0) > 0)
            || (desiredFields.contains(.phoneNumber) && (phone?.count ?? 0) > 0)
            || (desiredFields.contains(.postalAddress) && hasPartialPostalAddress())
    }

    /// Converts an STPBillingAddressFields enum value into the closest equivalent
    /// representation of PKContactField options
    /// - Parameter billingAddressFields: Stripe billing address fields enum value to convert.
    /// - Returns: The closest representation of the billing address requirement as
    /// a PKContactField value.
    @objc(applePayContactFieldsFromBillingAddressFields:)
    public class func applePayContactFields(
        from billingAddressFields: STPBillingAddressFields
    )
        -> Set<PKContactField>
    {
        switch billingAddressFields {
        case .none:
            return Set<PKContactField>([])
        case .postalCode, .full:
            return Set<PKContactField>([.name, .postalAddress])
        case .name:
            return Set<PKContactField>([.name])
        case .zip:
            return Set()
        @unknown default:
            fatalError()
        }
    }

    /// Converts a set of STPContactField values into the closest equivalent
    /// representation of PKContactField options
    /// - Parameter contactFields: Stripe contact fields values to convert.
    /// - Returns: The closest representation of the contact fields as
    /// a PKContactField value.
    @objc
    public class func pkContactFields(
        fromStripeContactFields contactFields: Set<STPContactField>?
    ) -> Set<PKContactField>? {
        guard let contactFields = contactFields else {
            return nil
        }

        var pkFields: Set<PKContactField> = Set()
        let stripeToPayKitContactMap: [STPContactField: PKContactField] = [
            STPContactField.postalAddress: PKContactField.postalAddress,
            STPContactField.emailAddress: PKContactField.emailAddress,
            STPContactField.phoneNumber: PKContactField.phoneNumber,
            STPContactField.name: PKContactField.name,
        ]

        for contactField in contactFields {
            if let convertedField = stripeToPayKitContactMap[contactField] {
                pkFields.insert(convertedField)
            }
        }
        return pkFields
    }

    private func hasValidPostalAddress() -> Bool {
        return (line1?.count ?? 0) > 0 && (city?.count ?? 0) > 0 && (country?.count ?? 0) > 0
            && ((state?.count ?? 0) > 0 || !(country == "US"))
            && (STPPostalCodeValidator.validationState(
                forPostalCode: postalCode,
                countryCode: country
            ) == .valid)
    }
}
