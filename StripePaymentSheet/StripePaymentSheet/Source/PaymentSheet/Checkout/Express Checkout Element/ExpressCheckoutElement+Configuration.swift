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

        /// Called after a wallet payment confirmation completes.
        public var confirmHandler: ConfirmHandler = { _ in }

        /// Controls appearance of Express Checkout Element.
        public var appearance: Appearance = .init()

        /// Creates a configuration with default values.
        public init() {}
    }

    public struct Appearance {
        /// Controls the theme of express payment buttons.
        public enum ButtonTheme {
            /// Light theme which contrasts with a dark background.
            case light
            /// Dark theme which contrasts with a light background.
            case dark
            /// Automatic theme which contrasts with background depending on system theme.
            case automatic
        }

        /// Controls the layout of express payment buttons.
        public struct ButtonLayout {
            /// Maximum number of columns. nil uses the default.
            public var maxColumns: Int?
            /// Maximum number of rows. nil uses the default.
            public var maxRows: Int?
            public init() {}
        }

        /// Theme of the express payment buttons.
        public var buttonTheme: ButtonTheme = .automatic

        /// Layout of the express payment buttons.
        public var buttonLayout: ButtonLayout = .init()

        public init() {}
    }
}
