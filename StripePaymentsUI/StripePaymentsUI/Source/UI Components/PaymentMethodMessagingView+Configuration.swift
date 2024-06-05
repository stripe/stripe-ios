//
//  PaymentMethodMessagingView+Configuration.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 9/29/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import UIKit

@_spi(STP) extension PaymentMethodMessagingView {
    /// 🏗 Under construction
    ///
    /// Configuration for the `PaymentMethodMessagingView` class.
    public struct Configuration {
        /// Initializes a `PaymentMethodMessagingView.Configuration`
        public init(
            apiClient: STPAPIClient = .shared,
            paymentMethods: [PaymentMethodMessagingView.Configuration.PaymentMethod],
            currency: String,
            amount: Int,
            locale: Locale = Locale.current,
            countryCode: String = Locale.current.stp_regionCode ?? "",
            font: UIFont = .preferredFont(forTextStyle: .footnote),
            textColor: UIColor = .label,
            imageColor: (
                userInterfaceStyleLight: PaymentMethodMessagingView.Configuration.ImageColor,
                userInterfaceStyleDark: PaymentMethodMessagingView.Configuration.ImageColor
            ) = (userInterfaceStyleLight: .dark, userInterfaceStyleDark: .light)
        ) {
            self.apiClient = apiClient
            self.paymentMethods = paymentMethods
            self.currency = currency
            self.amount = amount
            self.locale = locale
            self.countryCode = countryCode
            self.font = font
            self.textColor = textColor
            self.imageColor = imageColor
        }

        /// Payment methods that can be displayed by `PaymentMethodMessagingView`
        public enum PaymentMethod: CaseIterable {
            case klarna
            case afterpayClearpay
        }
        /// The APIClient instance used to make requests to Stripe
        public var apiClient: STPAPIClient = .shared
        /// The payment methods to display messaging for.
        public var paymentMethods: [PaymentMethod]
        /// The currency, as a three-letter ISO currency code.
        public var currency: String
        /// The purchase amount, in the smallest currency unit. e.g. 100 for $1 USD.
        public var amount: Int
        /// The customer's locale. Defaults to the device locale.
        public var locale: Locale = Locale.current
        /// The customer's country as a two-letter string. Defaults to their device's country.
        public var countryCode: String = Locale.current.stp_regionCode ?? ""
        /// The font of text displayed in the view. Defaults to the system font.
        public var font: UIFont = .preferredFont(forTextStyle: .footnote)
        /// The color of text displayed in the view. Defaults to `UIColor.labelColor`.
        public var textColor: UIColor = .label

        /// The colors of the image
        public enum ImageColor {
            case light
            case dark
            case color
        }
        /// The color of the images displayed in the view as a tuple specifying the color to use in light and dark mode.
        /// Defaults to `(.dark, .light)`.
        public var imageColor:
            (userInterfaceStyleLight: ImageColor, userInterfaceStyleDark: ImageColor) = (
                userInterfaceStyleLight: .dark, userInterfaceStyleDark: .light
            )
    }
}

extension PaymentMethodMessagingView {
    /// PaymentMethodMessagingView errors
    enum Error: Swift.Error {
        /// The view failed to initialize the attributed string
        case failedToInitializeAttributedString
    }
}
