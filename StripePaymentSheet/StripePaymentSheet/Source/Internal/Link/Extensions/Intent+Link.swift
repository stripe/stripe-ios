//
//  Intent+Link.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments

extension Intent {
    var supportsLink: Bool {
        return recommendedPaymentMethodTypes.contains(.link)
    }

    var supportsLinkCard: Bool {
        return supportsLink && (linkFundingSources?.contains(.card) ?? false)
    }

    var onlySupportsLinkBank: Bool {
        return supportsLink && (linkFundingSources == [.bankAccount])
    }

    var callToAction: ConfirmButton.CallToActionType {
        switch self {
        case .paymentIntent(let paymentIntent):
            return .pay(amount: paymentIntent.amount, currency: paymentIntent.currency)
        case .setupIntent:
            return .setup
        }
    }

    var linkFundingSources: Set<LinkSettings.FundingSource>? {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.linkSettings?.fundingSources
        case .setupIntent(let setupIntent):
            return setupIntent.linkSettings?.fundingSources
        }
    }

    var countryCode: String? {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.countryCode
        case .setupIntent(let setupIntent):
            return setupIntent.countryCode
        }
    }
}
