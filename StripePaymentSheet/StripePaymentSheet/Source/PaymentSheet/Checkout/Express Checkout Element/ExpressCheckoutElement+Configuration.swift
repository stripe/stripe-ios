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

        /// Controls which payment methods are displayed.
          public struct PaymentMethods {
              public enum ApplePayVisibility { case auto, always, never }
              public enum LinkVisibility { case auto, always, never }
              /// Default: `.auto`
              public var applePay: ApplePayVisibility = .auto
              /// Default: `.auto`
              public var link: LinkVisibility = .auto
              public init() {}
          }

        /// Controls which payment methods are displayed.
        public var paymentMethods: PaymentMethods = .init()

        /// Creates a configuration with default values.
        public init() {}
    }
}
