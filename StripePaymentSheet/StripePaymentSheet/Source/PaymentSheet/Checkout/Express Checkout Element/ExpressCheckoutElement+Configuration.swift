//
//  ExpressCheckoutElement+Configuration.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit

@_spi(STP)
@_spi(ReactNativeSDK)
extension ExpressCheckoutElement {
    /// Configuration options for ``ExpressCheckoutElement``.
    public struct Configuration {
        /// Configuration for collecting billing details.
        public var billingDetailsCollectionConfiguration: BillingDetailsCollectionConfiguration = .init()

        /// A closure called after a wallet payment confirmation completes.
        public typealias ConfirmHandler = (_ result: Checkout.ConfirmResult) -> Void

        /// Called after a wallet payment confirmation completes.
        public var confirmHandler: ConfirmHandler = { _ in }

        /// Creates an Express Checkout Element configuration with default values.
        public init() {}
    }
    /// Configuration for how billing details are collected during checkout.
    public struct BillingDetailsCollectionConfiguration: Equatable {
        /// Billing details fields collection options.
        public enum CollectionMode: String, CaseIterable {
            /// The field will be collected depending on the Payment Method's requirements.
            case automatic
            /// The field will never be collected.
            /// If this field is required by the Payment Method, you must provide it as part of `defaultBillingDetails`.
            case never
            /// The field will always be collected, even if it isn't required for the Payment Method.
            case always
        }

        /// Billing address collection options.
        public enum AddressCollectionMode: String, CaseIterable {
            /// Only the fields required by the Payment Method will be collected, this may be none.
            case automatic
            /// Collect the full billing address, regardless of the Payment Method requirements.
            case full
        }

        /// How to collect the name field.
        /// Defaults to `automatic`.
        public var name: CollectionMode = .automatic

        /// How to collect the phone field.
        /// Defaults to `automatic`.
        public var phone: CollectionMode = .automatic

        /// How to collect the email field.
        /// Defaults to `automatic`.
        public var email: CollectionMode = .automatic

        /// How to collect the billing address.
        /// Defaults to `automatic`.
        public var address: AddressCollectionMode = .automatic

        public init(
            name: CollectionMode = .automatic,
            phone: CollectionMode = .automatic,
            email: CollectionMode = .automatic,
            address: AddressCollectionMode = .automatic
        ) {
            self.name = name
            self.phone = phone
            self.email = email
            self.address = address
        }
    }
}

extension ExpressCheckoutElement.BillingDetailsCollectionConfiguration {
    /// Converts to the equivalent `PaymentSheet.BillingDetailsCollectionConfiguration`, used to
    /// apply these requirements to the Link confirmation flow.
    var asPaymentSheetConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration {
        func collectionMode(_ mode: CollectionMode) -> PaymentSheet.BillingDetailsCollectionConfiguration.CollectionMode {
            switch mode {
            case .automatic: return .automatic
            case .never: return .never
            case .always: return .always
            }
        }
        return PaymentSheet.BillingDetailsCollectionConfiguration(
            name: collectionMode(name),
            phone: collectionMode(phone),
            email: collectionMode(email),
            address: address == .full ? .full : .automatic
        )
    }
}
