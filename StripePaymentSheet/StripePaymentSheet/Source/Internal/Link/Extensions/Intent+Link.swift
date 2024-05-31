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
        // Either Link is an allowed Payment Method in the elements/sessions response, or passthrough mode (Link as a Card PM) is allowed
        return recommendedPaymentMethodTypes.contains(.link) || linkPassthroughModeEnabled
    }

    var supportsLinkCard: Bool {
        return supportsLink && (linkFundingSources?.contains(.card) ?? false) || linkPassthroughModeEnabled
    }

    var linkFlags: [String: Bool] {
        switch self {
        case .paymentIntent(let paymentIntent, _):
            return paymentIntent.linkSettings?.linkFlags ?? [:]
        case .setupIntent(let setupIntent, _):
            return setupIntent.linkSettings?.linkFlags ?? [:]
        case .deferredIntent(let elementsSession, _):
            return elementsSession.linkSettings?.linkFlags ?? [:]
        }
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

    var linkPassthroughModeEnabled: Bool {
        switch self {
        case .paymentIntent(let paymentIntent, _):
            return paymentIntent.linkSettings?.passthroughModeEnabled ?? false
        case .setupIntent(let setupIntent, _):
            return setupIntent.linkSettings?.passthroughModeEnabled ?? false
        case .deferredIntent(let elementsSession, _):
            return elementsSession.linkSettings?.passthroughModeEnabled ?? false
        }
    }

    var disableLinkSignup: Bool {
        switch self {
        case .paymentIntent(let paymentIntent, _):
            return paymentIntent.linkSettings?.disableSignup ?? false
        case .setupIntent(let setupIntent, _):
            return setupIntent.linkSettings?.disableSignup ?? false
        case .deferredIntent(let elementsSession, _):
            return elementsSession.linkSettings?.disableSignup ?? false
        }
    }

    var linkFundingSources: Set<LinkSettings.FundingSource>? {
        return elementsSession.linkSettings?.fundingSources
    }

    var linkPopupWebviewOption: LinkSettings.PopupWebviewOption {
        return elementsSession.linkSettings?.popupWebviewOption ?? .shared
    }

    func countryCode(overrideCountry: String?) -> String? {
#if DEBUG
        if let overrideCountry {
            return overrideCountry
        }
#endif
        return elementsSession.countryCode
    }

    var merchantCountryCode: String? {
        return elementsSession.merchantCountryCode
    }
}
