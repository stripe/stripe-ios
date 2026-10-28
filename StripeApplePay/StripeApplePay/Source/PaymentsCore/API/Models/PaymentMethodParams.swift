//
//  PaymentMethodParams.swift
//  StripeApplePay
//
//  Created by David Estes on 6/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

extension StripeAPI {
    /// An object representing parameters used to create a PaymentMethod object.
    /// - seealso: https://stripe.com/docs/api/payment_methods/create
    @_spi(InternalOnlyAPI) public struct PaymentMethodParams: UnknownFieldsEncodable {
        /// The type of payment method.
        /// The associated property will contain additional information (e.g. `type == .card` means `card` should also be populated).
        @_spi(InternalOnlyAPI) public var type: PaymentMethod.PaymentMethodType

        /// If this is a card PaymentMethod, this contains the user’s card details.
        @_spi(InternalOnlyAPI) public var card: Card?

        /// Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
        @_spi(InternalOnlyAPI) public var billingDetails: BillingDetails?

        /// Used internally to identify the version of the SDK sending the request
        @_spi(InternalOnlyAPI) public var paymentUserAgent: String? = {
            return PaymentsSDKVariant.paymentUserAgent
        }()

        /// Contains metadata with identifiers for the session and information about the integration
        @_spi(InternalOnlyAPI) public var clientAttributionMetadata: STPClientAttributionMetadata?

        /// :nodoc:
        @_spi(InternalOnlyAPI) public struct Card: UnknownFieldsEncodable {
            /// The card number, as a string without any separators. Ex. "4242424242424242"
            @_spi(InternalOnlyAPI) public var number: String?
            /// Number representing the card's expiration month. Ex. 1
            @_spi(InternalOnlyAPI) public var expMonth: Int?
            /// Two- or four-digit number representing the card's expiration year.
            @_spi(InternalOnlyAPI) public var expYear: Int?
            /// For backwards compatibility, you can alternatively set this as a Stripe token (e.g., for Apple Pay)
            @_spi(InternalOnlyAPI) public var token: String?
            /// Card security code. It is highly recommended to always include this value.
            @_spi(InternalOnlyAPI) public var cvc: String?

            /// The last 4 digits of the card's number, if it's been set, otherwise nil.
            @_spi(InternalOnlyAPI) public var last4: String? {
                if number != nil && (number?.count ?? 0) >= 4 {
                    return (number as NSString?)?.substring(from: (number?.count ?? 0) - 4)
                } else {
                    return nil
                }
            }
            @_spi(InternalOnlyAPI) public var _additionalParametersStorage: NonEncodableParameters?
        }

        @_spi(InternalOnlyAPI) public var _additionalParametersStorage: NonEncodableParameters?
    }
}

extension StripeAPI.PaymentMethodParams.Card: CustomStringConvertible, CustomDebugStringConvertible,
    CustomLeafReflectable
{
    @_spi(InternalOnlyAPI) public var debugDescription: String {
        return description
    }

    @_spi(InternalOnlyAPI) public var description: String {
        return "Card \(last4 ?? "")"
    }

    @_spi(InternalOnlyAPI) public var customMirror: Mirror {
        return Mirror(reflecting: self.description)
    }
}
