//
//  Intent+Link.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments

extension Intent {
    func supportsLink(allowV2Features: Bool) -> Bool {
        // Either Link is an allowed Payment Method in the elements/sessions response, or passthrough mode (Link as a Card PM) is allowed
        return recommendedPaymentMethodTypes.contains(.link) || (linkPassthroughModeEnabled && allowV2Features)
    }

    func supportsLinkCard(allowV2Features: Bool) -> Bool {
        return supportsLink(allowV2Features: allowV2Features) && (linkFundingSources?.contains(.card) ?? false) || (linkPassthroughModeEnabled && allowV2Features)
    }

    var onlySupportsLinkBank: Bool {
        return supportsLink(allowV2Features: false) && (linkFundingSources == [.bankAccount])
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
