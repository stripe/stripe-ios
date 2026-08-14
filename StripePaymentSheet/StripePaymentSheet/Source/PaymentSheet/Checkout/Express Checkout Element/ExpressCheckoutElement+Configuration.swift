//
//  ExpressCheckoutElement+Configuration.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

@_spi(STP)
@_spi(ReactNativeSDK)
extension ExpressCheckoutElement {
    /// Configuration options for ``ExpressCheckoutElement``.
    public struct Configuration {
        
        /// Configuration for how billing details are collected during wallet payments (e.g. Apple Pay).
        public struct BillingDetailsCollectionConfiguration: Equatable {
            /// Billing details fields collection options.
            public enum CollectionMode: String, CaseIterable {
                /// The field will be collected depending on the Payment Method's requirements.
                case automatic
                /// The field will never be collected.
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

            /// Creates a billing details collection configuration with default values.
            public init() {}
        }

        /// A closure called after a wallet payment confirmation completes.
        public typealias ConfirmHandler = (_ result: Checkout.ConfirmResult) -> Void

        /// Describes how billing details should be collected.
        ///
        /// - Note: Unlike ``PaymentElement/BillingDetailsCollectionConfiguration``, suppressing billing
        /// address collection isn't supported with a Checkout Session, so `address` has no `.never` case.
        public var billingDetailsCollectionConfiguration: BillingDetailsCollectionConfiguration = .init()

        /// Called after a wallet payment confirmation completes.
        public var confirmHandler: ConfirmHandler

        /// Creates a configuration.
        /// - Parameter confirmHandler: Called after a wallet payment confirmation completes.
        public init(confirmHandler: @escaping ConfirmHandler) {
            self.confirmHandler = confirmHandler
        }
    }
}
