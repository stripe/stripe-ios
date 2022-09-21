//
//  PaymentMethodMessagingView+Configuration.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 9/29/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore

@_spi(STP) public extension PaymentMethodMessagingView {
    /**
     🏗 Under construction
     
     Configuration for the `PaymentMethodMessagingView` class.
     */
    struct Configuration {
        public init(paymentMethods: [PaymentMethodMessagingView.Configuration.PaymentMethod], currency: String, amount: Int, locale: Locale = Locale.current, countryCode: String = Locale.current.regionCode ?? "", apiClient: STPAPIClient = .shared) {
            self.paymentMethods = paymentMethods
            self.currency = currency
            self.amount = amount
            self.locale = locale
            self.countryCode = countryCode
            self.apiClient = apiClient
        }
        
        /// Payment methods that can be displayed by `PaymentMethodMessagingView`
        public enum PaymentMethod {
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
        public var countryCode: String = Locale.current.regionCode ?? ""
        /// The font of text displayed in the view. Defaults to the system font.
        public var font: UIFont = .preferredFont(forTextStyle: .footnote)
        /// The color of text displayed in the view. Defaults to `UIColor.labelColor`.
        /// - Note: The color of images displayed in `PaymentMethodMessagingView` is either white or black, whichever color is closest to `textColor`.
        public var textColor: UIColor = .label
        
        enum ImageColor: String {
            case white
            case black
            case color
        }
        var imageColor: (userInterfaceStyleLight: ImageColor, userInterfaceStyleDark: ImageColor) = (userInterfaceStyleLight: .black, userInterfaceStyleDark: .white)
    }
}

extension PaymentMethodMessagingView {
    /// PaymentMethodMessagingView errors
    enum Error: Swift.Error {
        /// The view failed to initialize the attributed string
        case failedToInitializeAttributedString
    }
}
