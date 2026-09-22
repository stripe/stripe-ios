//
//  ExpressCheckoutElement+Configuration.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit
@_spi(STP) import StripeCore

@_spi(STP)
@_spi(ReactNativeSDK)
extension ExpressCheckoutElement {
    /// Configuration options for ``ExpressCheckoutElement``.
    public struct Configuration {
        /// Whether to require collecting a shipping address. Default: `false`.
        public var shippingAddressRequired: Bool = false
        /// Sets the configuration for Apple Pay.
        public var applePayConfiguration: ApplePayConfiguration?
        /// Sets the configuration for Link.
        public var linkConfiguration: LinkConfiguration = .init()
        /// Called after a wallet payment confirmation completes.
        public var confirmHandler: ConfirmHandler

        /// Controls appearance of Express Checkout Element.
        public var appearance: Appearance = .init()

        /// Creates a configuration with default values.
        public init(confirmHandler: @escaping ConfirmHandler) {
            self.confirmHandler = confirmHandler
        }
    }

    /// Configuration for Apple Pay.
    public struct ApplePayConfiguration: CheckoutApplePayConfiguration {
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

        /// Creates a Link configuration.
        public init(display: Display = .automatic) {
            self.display = display
        }
    }

    public struct Appearance {
        /// Controls the theme of Apple Pay buttons. Link buttons retain Link's required brand styling.
        public enum ButtonTheme: String {
            /// Light theme which contrasts with a dark background.
            case light
            /// Dark theme which contrasts with a light background.
            case dark
            /// Automatic theme which contrasts with background depending on system theme.
            case automatic
        }

        /// Controls the layout of express payment buttons.
        public struct ButtonLayout {
            /// Maximum number of columns. `nil` uses the default. Must be greater than zero when set.
            public var maxColumns: Int? {
                didSet {
                    guard let maxColumns, maxColumns <= 0 else { return }
                    assertionFailure("maxColumns must be greater than zero")
                    self.maxColumns = oldValue
                }
            }
            /// Maximum number of rows. `nil` uses the default. Must be greater than zero when set.
            public var maxRows: Int? {
                didSet {
                    guard let maxRows, maxRows <= 0 else { return }
                    assertionFailure("maxRows must be greater than zero")
                    self.maxRows = oldValue
                }
            }
            public init() {}
        }

        /// Theme of Apple Pay buttons. Link buttons retain Link's required brand styling.
        public var buttonTheme: ButtonTheme = .automatic

        /// Layout of the express payment buttons.
        public var buttonLayout: ButtonLayout = .init()

        public init() {}
    }

    /// A closure called after a wallet payment confirmation completes.
    public typealias ConfirmHandler = (_ result: CheckoutController.ConfirmResult) -> Void
}
