//
//  Checkout+Configuration.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/9/26.
//

import Foundation
@_spi(STP) import StripeCore

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// Configuration options for a ``Checkout`` instance.
    ///
    /// Supply a configuration when creating a ``Checkout`` to customize behavior:
    ///
    /// ```swift
    /// var config = Checkout.Configuration(clientSecret: "cs_xxx_secret_yyy")
    /// config.adaptivePricing.allowed = true
    ///
    /// let checkout = try await Checkout(configuration: config)
    /// ```
    public struct Configuration {
        /// The client secret for your Checkout Session.
        public var clientSecret: String

        /// The API client used to make requests to Stripe.
        public var apiClient: STPAPIClient = .shared

        /// Controls whether adaptive pricing is requested for this session.
        ///
        /// When allowed, Stripe may present prices in the customer's local
        /// currency alongside the merchant's settlement currency.
        ///
        /// Default: ``AdaptivePricing.init()`` (`allowed: false`).
        public var adaptivePricing: AdaptivePricing = AdaptivePricing()

        /// Configuration for PaymentElement.
        public var paymentElement: PaymentElement.Configuration = .init()

        /// Creates a configuration.
        /// - Parameter clientSecret: The client secret for your Checkout Session.
        public init(clientSecret: String) {
            self.clientSecret = clientSecret
        }
    }
}

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout.Configuration {
    /// Options for adaptive pricing behavior.
    ///
    /// Adaptive pricing lets customers see prices converted to their local
    /// currency. When ``allowed`` is `true`, the Checkout Session
    /// init request tells Stripe that the integration supports adaptive pricing;
    /// Stripe then decides whether to activate it based on the session's
    /// server-side configuration.
    public struct AdaptivePricing {
        /// Whether the integration allows adaptive pricing for this session.
        ///
        /// Set to `true` to have Stripe activate adaptive pricing,
        /// returning localized currency amounts.
        ///
        /// Default: `false`.
        public var allowed: Bool = false

        /// Creates an adaptive pricing configuration with default values.
        public init() {}
    }
}
