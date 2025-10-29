//
//  PaymentMethodMessagingElement.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/9/25.
//

import UIKit

/// An element that provides a view with information about how a purchase could be paid for using Buy Now, Pay Later payment methods.
public class PaymentMethodMessagingElement {

    /// Describes the visual appearance of the PaymentMethodMessagingElement.
    public struct Appearance {

        /// The color scheme style of the PaymentMethodMessagingElement.
        public enum UserInterfaceStyle {
            /// (Default) The PaymentMethodMessagingElement will automatically switch between standard and dark mode compatible colors based on device settings.
            case automatic
            /// The PaymentMethodMessagingElement will always use colors apporpriate for the standard (non-dark mode) UI.
            case alwaysLight
            /// The PaymentMethodMessagingElement will always use colors appropriate for dark mode UI.
            case alwaysDark
            /// The PaymentMethodMessagingElement will always use colors appropriate for a flat style, which uses grayscale colors.
            case flat
        }

        /// The color scheme style of the PaymentMethodElement.
        /// Defaults to `automatic`.
        public var style: UserInterfaceStyle = .automatic

        /// The font for the PaymentMethodElement's text.
        /// Defaults to the system font with size `UIFont.labelFontSize`.
        public var font: UIFont = UIFont.systemFont(ofSize: UIFont.labelFontSize)

        /// The color for the PaymentMethodElement's text.
        /// Defaults to the system `UIColor.label`.
        public var textColor: UIColor = .label

        /// The color for the PaymentMethodElement's info icon.
        /// Defaults to `textColor`.
        public var infoIconColor: UIColor?
    }

    /// Describes the configuration of the PaymentMethodMessagingElement.
    public struct Configuration {

        /// The amount intended to be collected in the smallest currency unit (for example, 100 cents to charge $1.00 USD).
        public let amount: Int

        /// The three-letter ISO currency code.
        public let currency: String

        /// The APIClient instance used to make requests to Stripe
        public var apiClient: STPAPIClient = STPAPIClient.shared

        /// The locale code used to localize text displayed in the element. See [the Stripe documentation](https://docs.stripe.com/js/appendix/supported_locales) for a list of supported values.
        /// Defaults to the current device locale identifier.
        /// - Warning: Not all device locales are supported by Stripe, and English will be used in the case of an unsupported locale. If you want to ensure a specific locale is used, pass it explicitly.
        public var locale: String = Locale.current.identifier

        /// The two letter country code of the user's location. If not provided, country will be determined based on IP Address.
        public var countryCode: String?

        /// The payment methods to request messaging for. Valid values are `.affirm`, `.klarna`, and `.afterpayClearpay`.
        /// Defaults to `nil`.
        /// If `nil`, uses your preferences from the Stripe dashboard to show the relevant payment methods. See Dynamic payment methods for more information.
        public var paymentMethodTypes: [STPPaymentMethodType]?

        /// Describes the visual appearance of the PaymentMethodMessaingElement.
        public var appearance: PaymentMethodMessagingElement.Appearance = PaymentMethodMessagingElement.Appearance()
    }

    // MARK: - Internal

    let mode: Mode
    let infoUrl: URL
    let promotion: String
    let appearance: Appearance

    init(mode: Mode, infoUrl: URL, promotion: String, appearance: PaymentMethodMessagingElement.Appearance) {
        self.mode = mode
        self.infoUrl = infoUrl
        self.promotion = promotion
        self.appearance = appearance
    }
}
