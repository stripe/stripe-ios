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
    /// var config = Checkout.Configuration(
    ///     clientSecret: "cs_xxx_secret_yyy",
    ///     returnURL: "my-app://stripe-redirect"
    /// )
    /// config.adaptivePricing.allowed = true
    ///
    /// let checkout = try await Checkout(configuration: config)
    /// ```
    public struct Configuration {
        /// The client secret for your Checkout Session.
        public var clientSecret: String

        /// A custom URL scheme that redirects back to your app after authenticating a payment method, e.g. `my-app://stripe-redirect`. Register this URL scheme in your app and forward incoming URLs to `StripeAPI.handleURLCallback(with:)`.
        public var returnURL: String

        /// The API client used to make requests to Stripe.
        public var apiClient: STPAPIClient = .shared

        /// Default customer details used to pre-populate Checkout integrations.
        public var defaults: Defaults = Defaults()

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
        /// - Parameter returnURL: A custom URL scheme that redirects back to your app after authenticating a payment method, e.g. `my-app://stripe-redirect`. Register this URL scheme in your app and forward incoming URLs to `StripeAPI.handleURLCallback(with:)`.
        public init(clientSecret: String, returnURL: String) {
            self.clientSecret = clientSecret
            self.returnURL = returnURL
        }

#if DEBUG
        /// Debug-only listener used to verify Checkout return URLs can be routed through
        /// `StripeAPI.handleURLCallback(with:)`.
        ///
        /// Checkout receives its return URL before any payment authentication flow has
        /// registered a real `STPPaymentHandler` listener. This temporary listener lets us
        /// exercise the same callback router during configuration so malformed callback
        /// URLs or missing app forwarding are caught earlier in integration.
        private final class ReturnURLCallbackListener: NSObject, STPURLCallbackListener {
            var handledURL: URL?

            func handleURLCallback(_ url: URL) -> Bool {
                handledURL = url
                return true
            }
        }
#endif

        func validateReturnURL() {
            #if DEBUG
            guard let url = URL(string: returnURL),
                  let scheme = url.scheme,
                  !scheme.isEmpty else {
                assertionFailure("Checkout.Configuration.returnURL must be a valid URL with a scheme.")
                return
            }

            let listener = ReturnURLCallbackListener()
            STPURLCallbackHandler.shared().register(listener, for: url)
            let handled = StripeAPI.handleURLCallback(with: url)
            STPURLCallbackHandler.shared().unregisterListener(listener)
            assert(
                handled && listener.handledURL == url,
                "Checkout.Configuration.returnURL must be forwarded to StripeAPI.handleURLCallback(with:) when your app receives the URL in application(_:open:options:) or scene(_:openURLContexts:)."
            )

            guard scheme.lowercased() != "http" && scheme.lowercased() != "https" else {
                return
            }

            let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]]
            let registeredSchemes = urlTypes?
                .flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
                .map { $0.lowercased() } ?? []
            assert(
                registeredSchemes.contains(scheme.lowercased()),
                "Checkout.Configuration.returnURL uses the custom URL scheme '\(scheme)', but it is not registered in CFBundleURLTypes."
            )
            #endif
        }
    }
}

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout.Configuration {
    /// Default customer details used to pre-populate Checkout integrations.
    public struct Defaults {
        /// Default billing details.
        public var billingDetails: BillingDetails?

        /// Default shipping details.
        public var shippingDetails: ShippingDetails?

        /// Creates default customer details.
        public init() {}

        /// Default billing details.
        public struct BillingDetails {
            /// The customer's full name.
            public var name: String?

            /// The customer's billing address.
            public var address: Checkout.Address?

            /// Creates default billing details.
            public init() {}
        }

        /// Default shipping details.
        public struct ShippingDetails {
            /// The customer's full name.
            public var name: String?

            /// The customer's shipping address.
            public var address: Checkout.Address?

            /// Creates default shipping details.
            public init() {}
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
