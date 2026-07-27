//
//  ExpressCheckoutElementUtilities.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/27/26.
//

@_spi(STP) import StripeCore

enum ExpressCheckoutElementUtilities {
    static func resolveButtons(for session: Checkout.Session, configuration: Checkout.Configuration) -> [ExpressButton] {
        let eceConfig = configuration.expressCheckoutElement
        var buttons: [ExpressButton] = []

        for button in session.availableExpressButtonTypes {
            switch button {
            case .applePay:
                if eceConfig.applePay != .never,
                    configuration.applePayConfiguration != nil,
                    StripeAPI.deviceSupportsApplePay() {
                    buttons.append(.applePay)
                }
            case .link:
                if eceConfig.link != .never && configuration.linkConfiguration?.display != .never {
                    buttons.append(.link)
                }
            }
        }

        // .always: include even if the session does not advertise the wallet
        if eceConfig.applePay == .always,
            configuration.applePayConfiguration != nil,
            StripeAPI.deviceSupportsApplePay(),
            !buttons.contains(.applePay) {
            buttons.append(.applePay)
        }
        if eceConfig.link == .always, !buttons.contains(.link) {
            buttons.append(.link)
        }

        return buttons
    }
}
