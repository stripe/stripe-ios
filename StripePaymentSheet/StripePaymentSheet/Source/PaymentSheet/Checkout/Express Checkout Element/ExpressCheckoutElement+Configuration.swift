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

        /// Whether to require collecting a shipping address. Default: `false`.
        public var shippingAddressRequired: Bool = false

        /// Called after a wallet payment confirmation completes.
        public var confirmHandler: ConfirmHandler = { _ in }

        /// Creates a configuration with default values.
        public init() {}
    }
}
