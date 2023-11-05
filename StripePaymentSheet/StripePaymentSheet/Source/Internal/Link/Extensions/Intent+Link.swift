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
        case .paymentIntent(_, let paymentIntent):
            return .pay(amount: paymentIntent.amount, currency: paymentIntent.currency)
        case .setupIntent:
            return .setup
        case .deferredIntent(_, let intentConfig):
            switch intentConfig.mode {
            case .payment(let amount, let currency, _, _):
                return .pay(amount: amount, currency: currency)
            case .setup:
                return .setup
            }
        }
    }

    var linkFundingSources: Set<LinkSettings.FundingSource>? {
        return elementsSession.linkSettings?.fundingSources
    }

    var linkPopupWebviewOption: LinkSettings.PopupWebviewOption {
        return elementsSession.linkSettings?.popupWebviewOption ?? .shared
    }

    var countryCode: String? {
        return elementsSession.countryCode
    }

    var merchantCountryCode: String? {
        return elementsSession.merchantCountryCode
    }
}
