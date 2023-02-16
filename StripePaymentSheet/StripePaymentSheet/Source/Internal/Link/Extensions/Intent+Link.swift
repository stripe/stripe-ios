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
        case .deferredIntent:
            fatalError("TODO(DeferredIntent) - use mode")
        }
    }

    var linkFundingSources: Set<LinkSettings.FundingSource>? {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.linkSettings?.fundingSources
        case .setupIntent(let setupIntent):
            return setupIntent.linkSettings?.fundingSources
        case .deferredIntent:
            fatalError("TODO(DeferredIntent) - use link_settings in response")
        }
    }

    var countryCode: String? {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.countryCode
        case .setupIntent(let setupIntent):
            return setupIntent.countryCode
        case .deferredIntent:
            fatalError("TODO(DeferredIntent) - use country code in response")
        }
    }
}
