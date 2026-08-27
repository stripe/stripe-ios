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
extension CheckoutController {
    public typealias UserInterfaceStyle = PaymentSheet.UserInterfaceStyle

    /// Configuration options for a ``Checkout`` instance.
    ///
    /// Supply a configuration when creating a ``Checkout`` to customize behavior:
    ///
    /// ```swift
    /// var config = CheckoutController.Configuration(
    ///     clientSecret: "cs_xxx_secret_yyy",
    ///     returnURL: "my-app://stripe-redirect"
    /// )
    /// config.currencySelectorElement = .init()
    ///
    /// let checkout = try await CheckoutController(configuration: config)
    /// ```
    public struct Configuration {
        /// The client secret for your Checkout Session.
        public var clientSecret: String

        /// A custom URL scheme that redirects back to your app after authenticating a payment method, e.g. `my-app://stripe-redirect`. Register this URL scheme in your app and forward incoming URLs to `StripeAPI.handleURLCallback(with:)`.
        public var returnURL: String

        /// The API client used to make requests to Stripe.
        public var apiClient: STPAPIClient = .shared

        /// Customer-facing business name.
        ///
        /// If `nil`, Checkout uses the business name from your Dashboard's
        /// Business Public Details settings.
        public var merchantDisplayName: String?

        /// Default customer details used to pre-populate Checkout integrations.
        public var defaults: Defaults = Defaults()

        /// Configuration for PaymentElement.
        public var paymentElement: PaymentElement.Configuration = .init()

        /// Configuration for ExpressCheckoutElement.
        public var expressCheckoutElement: ExpressCheckoutElement.Configuration = .init()

        /// Configuration for Currency Selector Element.
        ///
        /// Set this property to enable Currency Selector Element when Adaptive
        /// Pricing is available. The default value is `nil`.
        public var currencySelectorElement: CurrencySelectorElement.Configuration?

        /// Configuration for the shipping address form returned by
        /// ``CheckoutController.getShippingAddressElement()``.
        public var shippingAddressElement: ShippingAddressElement.Configuration = .init()

        /// Link configuration.
        public var linkConfiguration: LinkConfiguration?

        /// The color styling to use for Checkout UI.
        public var userInterfaceStyle: UserInterfaceStyle = .automatic

        /// Creates a configuration.
        /// - Parameter clientSecret: The client secret for your Checkout Session.
        /// - Parameter returnURL: A custom URL scheme that redirects back to your app after authenticating a payment method, e.g. `my-app://stripe-redirect`. Register this URL scheme in your app and forward incoming URLs to `StripeAPI.handleURLCallback(with:)`.
        public init(clientSecret: String, returnURL: String) {
            self.clientSecret = clientSecret
            self.returnURL = returnURL
        }

        // MARK: - Debug-only return URL validation
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

        func validateReturnURL() {
            guard let url = URL(string: returnURL),
                  let scheme = url.scheme,
                  !scheme.isEmpty else {
                assertionFailure("CheckoutController.Configuration.returnURL must be a valid URL with a scheme.")
                return
            }

            let listener = ReturnURLCallbackListener()
            STPURLCallbackHandler.shared().register(listener, for: url)
            let handled = StripeAPI.handleURLCallback(with: url)
            STPURLCallbackHandler.shared().unregisterListener(listener)
            assert(
                handled && listener.handledURL == url,
                "CheckoutController.Configuration.returnURL must be forwarded to StripeAPI.handleURLCallback(with:) when your app receives the URL in application(_:open:options:) or scene(_:openURLContexts:)."
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
                "CheckoutController.Configuration.returnURL uses the custom URL scheme '\(scheme)', but it is not registered in CFBundleURLTypes."
            )
        }
#endif
    }
}

@_spi(STP)
@_spi(ReactNativeSDK)
extension CheckoutController.Configuration {
    /// Default customer details used to pre-populate Checkout integrations.
    public struct Defaults {
        /// Default billing details.
        public var billingDetails: BillingDetails?

        /// Default shipping details.
        public var shippingDetails: ShippingDetails?

        /// The customer's phone number.
        public var phone: String?

        /// The customer's email address.
        public var email: String?

        /// Creates default customer details.
        public init() {}

        /// Default billing details.
        public struct BillingDetails {
            /// The customer's full name.
            public var name: String?

            /// The customer's billing address.
            public var address: CheckoutController.Address?

            /// Creates default billing details.
            public init() {}
        }

        /// Default shipping details.
        public struct ShippingDetails {
            /// The customer's full name.
            public var name: String?

            /// The customer's shipping address.
            public var address: CheckoutController.Address?

            /// Creates default shipping details.
            public init() {}
        }
    }
}
