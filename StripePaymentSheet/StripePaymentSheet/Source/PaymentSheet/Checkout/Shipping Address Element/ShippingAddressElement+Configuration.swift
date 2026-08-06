//
//  ShippingAddressElement+Configuration.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/4/26.

@_spi(STP) import StripePaymentsUI

@_spi(STP)
@_spi(ReactNativeSDK)
extension ShippingAddressElement {
    /// Configuration for ``ShippingAddressElement``.
    public struct Configuration {
        /// The title displayed above the shipping address form.
        /// Defaults to the localized "Shipping address".
        public var title: String = .Localized.shipping_address

        /// The title of the primary button.
        /// Defaults to the localized "Save address".
        public var buttonTitle: String = .Localized.save_address

        /// Describes the appearance of the shipping address form.
        public var appearance: Appearance = .init()

        /// Creates a configuration with default values.
        public init() {}
    }
}
