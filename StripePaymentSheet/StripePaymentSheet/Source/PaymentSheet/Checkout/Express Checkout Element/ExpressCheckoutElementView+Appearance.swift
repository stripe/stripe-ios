//
//  ExpressCheckoutElementView+Appearance.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/23/26.
//

import UIKit

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout.ExpressCheckoutElementView {
    public struct Appearance {

        // MARK: - Dimensions

        /// Corner radius applied to the Apple Pay and Link buttons. Default is `6`.
        public var cornerRadius: CGFloat = 6

        /// Height of each payment button. Default is `44`.
        public var buttonHeight: CGFloat = 44

        /// Vertical spacing between buttons when multiple are shown. Default is `8`.
        public var buttonSpacing: CGFloat = 8

        /// Creates an appearance with default values.
        public init() {}
    }
}
