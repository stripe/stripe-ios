//
//  ExpressCheckoutElementUtilities.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/28/26.
//

@_spi(STP) import StripeCore

enum ExpressCheckoutElementUtilities {
    static func resolveButtons(for session: CheckoutController.Session, configuration: ExpressCheckoutElement.Configuration) -> [ExpressCheckoutElement.PaymentMethod] {
        var buttons: [ExpressCheckoutElement.PaymentMethod] = []
        for button in session.availableExpressButtonTypes {
            switch button {
            case .applePay:
                if let applePayConfiguration = configuration.applePayConfiguration,
                   applePayConfiguration.display != .never,
                   StripeAPI.deviceSupportsApplePay() {
                    buttons.append(.applePay)
                }
            case .link:
                if configuration.linkConfiguration.display != .never,
                   !configuration.shippingAddressRequired {
                    buttons.append(.link)
                }
            }
        }
        return buttons
    }
}
