//
//  ExpressCheckoutElementUtilities.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/28/26.
//

@_spi(STP) import StripeCore

enum ExpressCheckoutElementUtilities {
    static func resolveButtons(for session: Checkout.Session, configuration: Checkout.Configuration) -> [ExpressCheckoutElement.ExpressButton] {
        var buttons: [ExpressCheckoutElement.ExpressButton] = []
        for button in session.availableExpressButtonTypes {
            switch button {
            case .applePay:
                if configuration.applePayConfiguration != nil && StripeAPI.deviceSupportsApplePay() {
                    buttons.append(.applePay)
                }
            case .link:
                if configuration.linkConfiguration?.display != .never {
                    buttons.append(.link)
                }
            }
        }
        return buttons
    }
}
