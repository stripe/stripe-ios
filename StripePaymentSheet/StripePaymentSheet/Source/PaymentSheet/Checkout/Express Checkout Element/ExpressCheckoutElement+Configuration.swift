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
        /// A closure called after a wallet payment confirmation completes.
        public typealias ConfirmHandler = (_ result: CheckoutController.ConfirmResult) -> Void

        /// Called after a wallet payment confirmation completes.
        public var confirmHandler: ConfirmHandler = { _ in }

        /// Sets the configuration for Apple Pay.
        public var applePayConfiguration: ApplePayConfiguration?
        /// Sets the configuration for Link.
        public var linkConfiguration: LinkConfiguration = .init()

        /// Creates a configuration with default values.
        public init() {}
    }

    /// Configuration for Link.
    public struct LinkConfiguration {
        /// Controls whether Link is displayed.
        public enum Display: String {
            /// Show Link when it is available.
            case automatic
            /// Never show Link.
            case never
        }

        /// Controls whether Link is displayed.
        public var display: Display = .automatic

        /// Whether missing billing details should be collected for existing Link payment methods.
        @_spi(CollectMissingLinkBillingDetailsPreview) public var collectMissingBillingDetailsForExistingPaymentMethods: Bool = true

        /// Creates a Link configuration.
        public init(display: Display = .automatic) {
            self.display = display
        }
    }

    /// Configuration for Apple Pay.
    public struct ApplePayConfiguration {
        /// The Apple Pay merchant identifier.
        public let merchantId: String

        /// The type of Apple Pay button to display. Defaults to `.plain` when `nil`.
        public var buttonType: PKPaymentButtonType?

        /// Controls whether Apple Pay is displayed.
        public var display: Display = .automatic

        /// Controls whether Apple Pay is displayed.
        public enum Display: String {
            /// Show Apple Pay when it is available.
            case automatic
            /// Never show Apple Pay.
            case never
        }

        /// Creates an Apple Pay configuration.
        /// - Parameters:
        ///   - merchantId: The Apple Pay merchant identifier.
        ///   - buttonType: The type of Apple Pay button to display. Defaults to `.plain` when `nil`.
        ///   - display: Whether Apple Pay is displayed. Defaults to `.automatic`.
        public init(
            merchantId: String,
            buttonType: PKPaymentButtonType? = nil,
            display: Display = .automatic
        ) {
                self.merchantId = merchantId
            self.buttonType = buttonType
            self.display = display
        }
    }
}
