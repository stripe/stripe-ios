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
        /// A closure called after a wallet payment confirmation completes.
        public typealias ConfirmHandler = (_ result: CheckoutController.ConfirmResult) -> Void

        /// Configuration for collecting billing details.
        public var billingDetailsCollectionConfiguration: BillingDetailsCollectionConfiguration = .init()

        /// Called after a wallet payment confirmation completes.
        public var confirmHandler: ConfirmHandler = { _ in }

        /// Creates a configuration with default values.
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
    /// Converts this configuration into the canonical ``PaymentSheet/BillingDetailsCollectionConfiguration``
    /// so it can flow through shared Apple Pay/Checkout confirmation logic alongside Payment Element's config.
    func paymentSheetConfiguration() -> PaymentSheet.BillingDetailsCollectionConfiguration {
        var configuration = PaymentSheet.BillingDetailsCollectionConfiguration()
        configuration.name = PaymentSheet.BillingDetailsCollectionConfiguration.CollectionMode(rawValue: name.rawValue) ?? .automatic
        configuration.phone = PaymentSheet.BillingDetailsCollectionConfiguration.CollectionMode(rawValue: phone.rawValue) ?? .automatic
        configuration.email = PaymentSheet.BillingDetailsCollectionConfiguration.CollectionMode(rawValue: email.rawValue) ?? .automatic
        configuration.address = PaymentSheet.BillingDetailsCollectionConfiguration.AddressCollectionMode(rawValue: address.rawValue) ?? .automatic
        return configuration
    }
}
