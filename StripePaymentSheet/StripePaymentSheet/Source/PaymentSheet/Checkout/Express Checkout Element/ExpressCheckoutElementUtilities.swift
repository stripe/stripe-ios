//
//  ExpressCheckoutElementUtilities.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/27/26.
//

@_spi(STP) import StripeCore

enum ExpressCheckoutElementUtilities {
    static func resolveButtons(for session: Checkout.Session, configuration: Checkout.Configuration) -> [ExpressButton] {
        var buttons: [ExpressButton] = []
        for button in session.availableExpressButtonTypes {
            switch button {
            case .applePay:
                if configuration.applePayConfiguration != nil && StripeAPI.deviceSupportsApplePay() {
                    buttons.append(.applePay)
                }
            case .link:
                buttons.append(.link)
            }
        }
        return buttons
    }
}
